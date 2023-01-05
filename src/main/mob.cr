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
mob_id = nil
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


toxrpcsrv = Bobo::ToxRpc::Server.new(log: Log.for("toxrpc:mob"))
toxrpcsrv.bootstrap()
spawn name: "toxrpc tox iterate" do
  loop do
    toxrpcsrv.iterate()
  end
end
spawn name: "toxrpc runner" do
  toxrpcsrv.listen()
end
if !quiet
  puts "TOXID: #{toxrpcsrv.address}"
end

mob_id = toxrpcsrv.address
provider = Bobo::MobProvider::Local.new(mob_id.not_nil!, mob_directory)
app = Bobo::Application::Mob.new(provider)

mob = provider.create()

get "/id" do
  app.get_id
end

toxrpcsrv.handle("get_resource") do |arguments|
  id = arguments["id"].not_nil!

  resource = mob.get_resource(id)

  Bobo::Rpc::Reply.new()
end

if !quiet
  puts "MOB directory #{mob_directory}"
end

Kemal.run do |config|
  config.server.not_nil!.bind_tcp http_port
end
