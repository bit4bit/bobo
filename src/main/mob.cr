require "http/server"
require "option_parser"
require "dir"

require "log"

require "tox"
require "kemal"

require "../bobo"


Log.setup_from_env

quiet = false
command = nil
http_port = 65300
mob_directory = Dir.current

OptionParser.parse do |parser|
  parser.banner = "usage: bobo mob [arguments]"
  parser.on("-q", "--quiet", "QUIET") { |val| quiet = true }
  parser.on("-p PORT", "--port=PORT", "HTTP PORT") { |port| http_port = port.to_i }
  parser.on("-d DIRECTORY", "--mob-directory=DIRECTORY", "MOB DIRECTORY") { |path| mob_directory = path }
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
end.parse


if quiet
  logging false
end

log = Log.for("mob")
gateway = Bobo::Gateway::Mob.new()
app = Bobo::Application::Mob.new(gateway)

get "/:mob_id/resource" do |env|
  mob_id = env.params.url["mob_id"].not_nil!
  resource_id = env.request.headers.fetch("resource_id", nil).not_nil!.as(String)

  mob = gateway.get(mob_id)
  resource = mob.resource(resource_id).not_nil!

  HTTP::FormData.build(env.response, "boundary") do |builder|
    builder.field("id", resource.id)
    builder.field("programmer_id", resource.programmer_id)
    builder.field("hash", resource.hash)
    builder.field("relative_path", resource.relative_path)
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
    index += "#{resource.id}\n"
  end
  index
end

post "/:mob_id/drive/delete" do |env|
  mob_id = env.params.url["mob_id"].not_nil!
  programmer_id = env.params.body["programmer_id"].not_nil!
  resource_id = env.params.body["id"].not_nil!

  mob = gateway.get(mob_id)
  programmer = gateway.get_programmer(programmer_id)

  result = mob.release(programmer, resource_id)
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

  mob = gateway.get(mob_id)
  programmer = gateway.get_programmer(programmer_id)
  resource = Bobo::Resource.new(
    id: resource_id,
    programmer_id: programmer.id,
    relative_path: relative_path,
    hash: resource_hash,
    content: file
  )

  result = mob.drive(programmer, resource)
  if result.error?
    halt env, status_code: 403, response: result.error
  else
    log.debug { "new drive #{resource_id} of programmer #{programmer_id}" }

    env.response.status_code = 200
    "ok"
  end
end

if !quiet
  puts "MOB directory #{mob_directory}"
end

Kemal.run do |config|
  config.server.not_nil!.bind_tcp http_port
end
