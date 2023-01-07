require "http/server"
require "option_parser"
require "dir"

require "log"

require "tox"
require "kemal"

require "../bobo"


Log.setup_from_env

log = Log.for("programmer:gateway")

quiet = false
command = nil
mob_id = nil
mob_url = nil
programmer_id = nil
iteration_interval = 5
http_port = 65300
mob_directory = Dir.current

OptionParser.parse do |parser|
  parser.banner = "usage: bobo programmer [arguments]"
  parser.on("-q", "--quiet", "QUIET") { |val| quiet = true }
  parser.on("-p PORT", "--port=PORT", "HTTP PORT") { |port| http_port = port.to_i }
  parser.on("-d DIRECTORY", "--mob-directory=DIRECTORY", "MOB DIRECTORY") { |path| mob_directory = path }
  parser.on("-i MOBID", "--mob-id=MOBID", "MOB ID") { |id| mob_id = id }
  parser.on("-u PROGRAMMERID", "--programmer-id=PROGRAMERID", "MOB ID") { |id| programmer_id = id }
  parser.on("-l MOBURL", "--mob-url=MOBURL", "MOB URL") { |url| mob_url = url }
  parser.on("-t INTERVAL", "--internal=INTERVAL", "INTERVAL IN SECONDS") { |i| iteration_interval = i.to_i }
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
end.parse

if quiet
  logging false
end


raise "requires mob-id" if mob_id.nil?
raise "requires programmer-id" if programmer_id.nil?
raise "requires mob-url" if mob_url.nil?

require "./ssl_memory_client"
ssl = SSLMemoryClient.new
abort "SSL Certificate Not Found" if !File.exists?(ssl.cert_path)
sslctx = OpenSSL::SSL::Context::Client.new
sslctx.ca_certificates = ssl.cert_path

gateway = Bobo::Gateway::Programmer.new(mob_url.not_nil!,
                                        log,
                                        mob_directory,
                                        sslcontext: sslctx)
pgapp = Bobo::Application::Programmer.new(
  gateway: gateway,
  log: Log.for("programmer:application"),
  mob_directory: mob_directory
)

get "/mobid" do
  pgapp.get_mob_id(mob_id.not_nil!)
end

# MACHETE: delete /drive not works
post "/drive/delete" do |env|
  filepath = env.params.body["filepath"].as(String)

  result = pgapp.release(mob_id.not_nil!, programmer_id.not_nil!, filepath)

  if result.error?
    halt env, status_code: 503, response: result.error
  else
    result.ok
  end
end

post "/drive" do |env|
  filepath = env.params.body["filepath"].as(String)
  result = pgapp.drive(mob_id.not_nil!, programmer_id.not_nil!, filepath)
  if result.error?
    halt env, status_code: 503, response: result.error
  else
    env.response.status_code = 200
    result.ok
  end
end

# UI
require "./ui"
programmer_url = "http://localhost:#{http_port}"
ui = UI.new(pgapp: pgapp,
            programmer_url: programmer_url,
            mob_directory: mob_directory,
            log: log)
ui.install(mob_id.not_nil!, programmer_id.not_nil!, iteration_interval)
get "/ui" do |env|
  ui.browser(env)
end

post "/ui/action/drive" do |env|
  ui.action_drive(env)
end

post "/ui/action/release" do |env|
  ui.action_release(env)
end

if !quiet
  puts "MOB directory #{mob_directory}"
end

Kemal.run do |config|
  config.server.not_nil!.bind_tcp http_port
end
