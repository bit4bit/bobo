
require "http/server"
require "option_parser"
require "dir"

require "log"

require "kemal"

require "../bobo"
require "./tor"

Log.setup_from_env

log = Log.for("programmer:gateway")

tor_connect = false
tor_binary_path = nil
ssl_cert_path = nil
quiet = false
command = nil
mob_id = nil
mob_url = nil
programmer_id = nil
iteration_interval = 5
http_port = 65300
max_resource_content_size = 1024 * 300 #300KB
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
  parser.on("--max-resource-content-size=BYTES", "max file size in bytes") { |i| max_resource_content_size = i.to_i }
  parser.on("--tor", "ENABLE TOR PROXY") { tor_connect = true }
  parser.on("--tor-binary-path=PATH", "TOR BINARY PATH") { |path| tor_binary_path = path }
  parser.on("--ssl-cert-path=PATH", "SSL CERTIFICATE PATH") { |path| ssl_cert_path = path }
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


ssl_cert_path ||= "client.pem"
abort "SSL Certificate Not Found at #{ssl_cert_path}" if !File.exists?(ssl_cert_path.not_nil!)

sslctx = OpenSSL::SSL::Context::Client.new
sslctx.ca_certificates = ssl_cert_path.not_nil!

http_tunnel_port = nil
if tor_connect
  http_tunnel_port = Bobo::Tor::Config.ephemeral_port()
end

drives = Set(String).new()
event_provider = Bobo::Gateway::ProgrammerEventProvider.new(
  mob_url.not_nil!,
  mob_id.not_nil!,
  sslctx)
protocol = Bobo::Gateway::Protocol.new(sslctx, http_tunnel_port)
gateway = Bobo::Gateway::Programmer.new(mob_url.not_nil!,
                                        log,
                                        mob_directory,
                                        protocol: protocol)
resource_constraints = Bobo::Application::ResourceConstraints.constraints do |constraints|
  constraints.allowed_content_size = max_resource_content_size
end
pgapp = Bobo::Application::Programmer.new(
  gateway: gateway,
  log: Log.for("programmer:application"),
  resource_constraints: resource_constraints,
  mob_directory: mob_directory
)

get "/mobid" do
  pgapp.get_mob_id(mob_id.not_nil!)
end

# MACHETE: delete /drive not works
post "/handover" do |env|
  filepath = env.params.body["filepath"].as(String)

  result = pgapp.handover(mob_id.not_nil!, programmer_id.not_nil!, filepath)

  if result.error?
    halt env, status_code: 503, response: result.error
  else
    drives.delete(filepath)
    result.ok
  end
end

post "/drive" do |env|
  filepath = env.params.body["filepath"].as(String)
  result = pgapp.drive(mob_id.not_nil!, programmer_id.not_nil!, filepath)
  if result.error?
    halt env, status_code: 503, response: result.error
  else
    drives.add(filepath)
    env.response.status_code = 200
    result.ok
  end
end

get "/drives" do |env|
  drives.join("\n")
end

# EVENTS
event_provider.on_event do |tag, event|
  case event
  when Bobo::Application::Events::ResourceDrived
    pgapp.copiloting_resource(
      mob_id.not_nil!,
      event.metadata
    )
  end
end


# UI
require "./ui"
programmer_url = "http://localhost:#{http_port}"
ui = UI.new(
  mob_id: mob_id.not_nil!,
  programmer_id: programmer_id.not_nil!,
  pgapp: pgapp,
  pggw: gateway,
  programmer_url: programmer_url,
  mob_directory: mob_directory,
  log: log,
  drives: drives
)

get "/" do |env|
  env.redirect "/ui"
end

get "/ui" do |env|
  ui.browser(env)
end

post "/ui/action/drive" do |env|
  ui.action_drive(env)
end

post "/ui/action/handover" do |env|
  ui.action_handover(env)
end

spawn name: "event-provider" do
  event_provider.run
end

spawn do
  loop do
    pgapp.copiloting(mob_id.not_nil!, programmer_id.not_nil!)
    pgapp.driving(mob_id.not_nil!, programmer_id.not_nil!)
    sleep iteration_interval.second
  rescue ex : Exception
    log.error { ex.inspect_with_backtrace }
    sleep 15.second
  end
end
if !quiet
  puts "MOB directory #{mob_directory}"
end

if tor_connect
  spawn do
    Bobo::Tor::Server.run do |config|
      config.tor_alias = "programmer"
      config.http_tunnel_port = http_tunnel_port
      config.tor_binary_path = tor_binary_path
    end
    abort "tor stopped"
  end
end

Kemal.run do |config|
  config.server.not_nil!.bind_tcp http_port
end
