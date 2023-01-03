require "http/server"
require "option_parser"
require "dir"

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

case command
when :programmer
  raise "requires mob-id" if mob_id.nil?
  programmer = Bobo::Programmer.connect(mob_id.as(String), mob_directory)

  server = HTTP::Server.new do |context|
    case context.request.path
    when "/mobid"
      context.response.content_type = "text/plain"
      context.response.print programmer.mob_id
    end
  end

  if !quiet
    puts "Programmer listening on http://127.0.0.1:#{http_port}"
    puts "Programmer directory #{mob_directory}"
  end

  server.listen(http_port)
when :mobstart
  mob = Bobo::Mob.new()
  mob.start(mob_directory)

  server = HTTP::Server.new do |context|
    if context.request.path == "/id"
      context.response.content_type = "text/plain"
      context.response.print mob.id
    end
  end

  if !quiet
    puts "MOB Listening on http://127.0.0.1:#{http_port}"
    puts "MOB directory #{mob_directory}"
  end
  server.listen(http_port)
end
