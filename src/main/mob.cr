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

gateway = Bobo::Gateway::Mob.new()
app = Bobo::Application::Mob.new(gateway)

post "/:mob_id/drive" do |env|
  mob_id = env.params.url["mob_id"].not_nil!
  programmer_id = env.params.body["programmer_id"].not_nil!
  resource_hash = env.params.body["resource_hash"].not_nil!
  resource_id = env.params.body["resource_id"].not_nil!
  file = env.params.files["resource"].tempfile
  content = IO::Memory.new
  IO.copy(file, content)

  mob = gateway.get(mob_id)
  programmer = gateway.get_programmer(programmer_id)
  resource = Bobo::Resource.new(
    resource_id,
    programmer,
    resource_hash,
    content
  )

  result = mob.drive(programmer, resource)
  if result.fail?
    halt env, status_code: 403, response: result.error
  else
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
