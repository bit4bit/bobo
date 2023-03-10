require "http/server"
require "option_parser"
require "dir"

require "log"

require "kemal"

require "./auth"
require "../bobo"

Log.setup_from_env

ssl_key_path = nil
ssl_cert_path = nil
tor_onion = false
tor_binary_path = nil
quiet = false
command = nil
http_port = 65300
max_resource_content_size = 1024 * 300 # 300KB
mob_directory = Dir.current

OptionParser.parse do |parser|
  parser.banner = "usage: bobo mob [arguments]"
  parser.on("-q", "--quiet", "QUIET") { |val| quiet = true }
  parser.on("-p PORT", "--port=PORT", "HTTP PORT") { |port| http_port = port.to_i }
  parser.on("-d DIRECTORY", "--mob-directory=DIRECTORY", "MOB DIRECTORY") { |path| mob_directory = path }
  parser.on("--max-resource-content-size=BYTES", "max file size in bytes") { |i| max_resource_content_size = i.to_i }
  parser.on("--tor", "TOR ONION") { tor_onion = true }
  parser.on("--tor-binary-path=PATH", "TOR BINARY PATH") { |path| tor_binary_path = path }
  parser.on("--ssl-key-path=PATH", "SSL KEY PATH") { |path| ssl_key_path = path }
  parser.on("--ssl-cert-path=PATH", "SSL CERT PATH") { |path| ssl_cert_path = path }
  parser.on("-h", "--help", "Show this help") do
    puts parser
    puts "please generate ssl certificate and key using script/ssl_self.sh <hostname or tor hostname>"
    exit
  end
end.parse

ssl_key_path ||= "server.key"
ssl_cert_path ||= "server.pem"
abort "SSL Key Not Found" if !File.exists?(ssl_key_path.not_nil!)
abort "SSL Certificate Not Found" if !File.exists?(ssl_cert_path.not_nil!)
authorizer = Authorizer::Server.new(
  File.read(ssl_key_path.not_nil!)
)

if quiet
  logging false
end

log = Log.for("mob")
resource_constraints = Bobo::Application::ResourceConstraints.constraints do |constraints|
  constraints.allowed_content_size = max_resource_content_size
end
notification = Bobo::Gateway::MobNotification.new
gateway = Bobo::Gateway::Mob.new
app = Bobo::Application::Mob.new(
  gateway,
  resource_constraints: resource_constraints,
  notification: notification)

before_all do |env|
  x_auth = env.request.headers.fetch("X-AUTH", "")
  halt env, status_code: 401, response: "Unauthorized" unless authorizer.authorized?(x_auth)
end

get "/:mob_id/resource" do |env|
  mob_id = env.params.url["mob_id"].not_nil!
  resource_id = env.request.headers.fetch("resource_id", nil).not_nil!.as(String)

  mob = gateway.get(mob_id)
  resource = mob.resource(resource_id).not_nil!

  metadata = Bobo::ResourceMetadata.from_resource(resource)
  HTTP::FormData.build(env.response, "boundary") do |builder|
    builder.field("metadata", metadata.to_wire)
    builder.file("content", resource.content)
  end
  env.response.close
end

get "/:mob_id/:programmer_id/resources" do |env|
  mob_id = env.params.url["mob_id"].not_nil!
  programmer_id = env.params.url["programmer_id"].not_nil!

  mob = gateway.get(mob_id)
  programmer = gateway.get_programmer(programmer_id)

  resources = mob.resources_of_copilot(programmer)

  index = ""
  resources.each do |resource|
    metadata = Bobo::ResourceMetadata.from_resource(resource)
    index += metadata.to_wire + "\n"
  end
  index
end

post "/:mob_id/drive/delete" do |env|
  mob_id = env.params.url["mob_id"].not_nil!
  programmer_id = env.params.body["programmer_id"].not_nil!
  resource_id = env.params.body["id"].not_nil!

  result = app.handover(mob_id, programmer_id, resource_id)
  if result.error?
    halt env, status_code: 403, response: result.error
  else
    "ok"
  end
end

post "/:mob_id/drive" do |env|
  mob_id = env.params.url["mob_id"].not_nil!
  programmer_id = env.params.body["programmer_id"].not_nil!
  resource_hash = env.params.body["hash"].not_nil!
  resource_id = env.params.body["id"].not_nil!
  relative_path = env.params.body["relative_path"].not_nil!
  file = env.params.files["content"].tempfile

  resource = Bobo::Resource.new(
    id: resource_id,
    programmer_id: programmer_id,
    relative_path: Bobo::Path.new(relative_path),
    hash: resource_hash,
    content: file
  )

  result = app.drive(mob_id, resource)
  if result.error?
    halt env, status_code: 403, response: result.error
  else
    log.debug { "new drive #{resource_id} of programmer #{programmer_id}" }

    env.response.status_code = 200
    "ok"
  end
end

ws "/:mob_id/events" do |socket, context|
  x_auth = context.request.headers.fetch("X-AUTH", "")
  halt context, status_code: 401, response: "Unauthorized" unless authorizer.authorized?(x_auth)

  mob_id = context.ws_route_lookup.params["mob_id"]

  notification.subscribe_websocket(mob_id, socket)
end

if !quiet
  puts "MOB directory #{mob_directory}"
end

require "./tor"
if tor_onion
  spawn do
    Bobo::Tor::Server.run do |config|
      config.tor_alias = "mob"
      config.tor_onion = true
      config.tor_binary_path = tor_binary_path
      config.mob_http_port = http_port
    end
    abort "tor stopped"
  end
end

Kemal.run do |config|
  sslctx = OpenSSL::SSL::Context::Server.new
  sslctx.certificate_chain = ssl_cert_path.not_nil!
  sslctx.private_key = ssl_key_path.not_nil!
  sslctx.verify_mode = LibSSL::VerifyMode::PEER

  config.server.not_nil!.bind_tls "0.0.0.0", http_port, sslctx
end
