require "http/server"
require "option_parser"
require "dir"

require "kemal"

require "./bobo"



quiet = false
command = nil
mob_id = nil
http_port = 65300
mob_directory = Dir.current

OptionParser.parse do |parser|
  parser.banner = "usage: bobo [sucommand] [arguments]"
  parser.on("-q", "--quiet", "QUIET") { |val| quiet = true }
  parser.on("-p PORT", "--port=PORT", "HTTP PORT") { |port| http_port = port.to_i }

  parser.on("mob-start", "start a mob in current directory") do
    command = :mobstart
    parser.banner = "usage: bobo mob-start [arguments]"
  end
  parser.on("programmer", "start as programmer in current directory") do
    command = :programmer
    parser.banner = "usage: bobo programmer [arguments]"
    parser.on("-i MOBID", "--mob-id=MOBID", "MOB ID") { |id| mob_id = id }
  end
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
end.parse

provider = Bobo::Provider.new()
provider.start()

if quiet
  logging false
end


case command
when :programmer
  raise "requires mob-id" if mob_id.nil?
  programmer = Bobo::Programmer.connect(mob_id.as(String), mob_directory, provider: provider)

  get "/mobid" do
    programmer.mob_id
  end

  post "/drive" do |env|
    halt env, status_code: 503, response: "can't drive file example.rb mismatch content"
  end
when :mobstart
  mob = Bobo::Mob.new(provider)
  mob.start(mob_directory)

  get "/id" do
    mob.id
  end


end

if !quiet
  puts "MOB directory #{mob_directory}"
end

Kemal.run do |config|
  config.server.not_nil!.bind_tcp http_port
end
