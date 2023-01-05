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
  parser.banner = "usage: bobo programmer [arguments]"
  parser.on("-q", "--quiet", "QUIET") { |val| quiet = true }
  parser.on("-p PORT", "--port=PORT", "HTTP PORT") { |port| http_port = port.to_i }
  parser.on("-d DIRECTORY", "--mob-directory=DIRECTORY", "MOB DIRECTORY") { |path| mob_directory = path }
  parser.on("-i MOBID", "--mob-id=MOBID", "MOB ID") { |id| mob_id = id }
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
end.parse

if quiet
  logging false
end


raise "requires mob-id" if mob_id.nil?
toxrpc = Bobo::ToxRpc::Client.new(log: Log.for("toxrpc:programmer"))
toxrpc.bootstrap()
spawn name: "toxrpc tox iterate" do
  loop do
    toxrpc.iterate()
  end
end
spawn name: "toxrpc runner" do
    toxrpc.listen()
end
toxrpc.connect(Bobo::ToxRpc::Address.new(mob_id.not_nil!))

programmer_id = toxrpc.address
pgprovider = Bobo::ProgrammerProvider.new(programmer_id, mob_directory)
provider = Bobo::MobProvider::Remote.new(mob_id.not_nil!, mob_directory, toxrpc)
pgapp = Bobo::Application::Programmer.new(
  mob_provider: provider,
  programmer_provider: pgprovider,
  mob_directory: mob_directory
)

get "/mobid" do
  pgapp.get_mob_id(mob_id.not_nil!)
end

post "/drive" do |env|
  filepath = env.params.body["filepath"].as(String)
  result = pgapp.drive(mob_id.not_nil!, programmer_id, filepath)
  if result.fail?
    halt env, status_code: 503, response: result.error
  end

  result.ok
end

if !quiet
  puts "MOB directory #{mob_directory}"
end

Kemal.run do |config|
  config.server.not_nil!.bind_tcp http_port
end
