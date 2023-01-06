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

gateway = Bobo::Gateway::Programmer.new(programmer_id.not_nil!,
                                        mob_url.not_nil!,
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
drives = Set(String).new()
programmer_url = "http://localhost:#{http_port}"

def browser(env, mob_directory, drives)
  directory = env.params.query.fetch("directory", nil)
  up_directory = mob_directory
  up_directory = Path[directory].parent.relative_to(mob_directory).normalize.to_s if !directory.nil?
  directory = mob_directory if [".", ".."].includes?(directory)
  directory ||= mob_directory

  names = Dir.children(directory).map do |name|
    relname = Path[directory].join(name).relative_to(mob_directory).normalize.to_s
    if File.directory?(name)
      {relname, :directory}
    else
      {relname, :file}
    end
  end.reject {|n| drives.includes?(n[0]) }

  render "src/ui/views/index.html.ecr"
end
get "/ui" do |env|
  browser(env, mob_directory, drives)
end

post "/ui/action/drive" do |env|
  filepath = env.params.body["filepath"].as(String)

  begin
    resp = Crest.post("#{programmer_url}/drive", {"filepath" => filepath})
    if resp.status_code == 200
      drives.add(filepath)
    end
  rescue ex : Crest::RequestFailed
    log.error { ex.message }
  end

  browser(env, mob_directory, drives)
end

post "/ui/action/release" do |env|
  filepath = env.params.body["filepath"].as(String)

  begin
    resp = Crest.post("#{programmer_url}/drive/delete", {"filepath" => filepath})
    if resp.status_code == 200
      drives.delete(filepath)
    end
  rescue ex : Crest::RequestFailed
    log.error { ex.message }
  end

  browser(env, mob_directory, drives)
end

spawn do
  loop do
    pgapp.copilot(mob_id.not_nil!, programmer_id.not_nil!)
    sleep iteration_interval.second
  rescue ex : Exception
    log.error { ex.inspect_with_backtrace }
    sleep 15.second
  end
end

if !quiet
  puts "MOB directory #{mob_directory}"
end

Kemal.run do |config|
  config.server.not_nil!.bind_tcp http_port
end
