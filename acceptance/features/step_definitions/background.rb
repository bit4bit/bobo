require 'rake/file_utils'

fail 'not found command' unless File.exists?('../bin/bobo')

$command_path = File.absolute_path('../bin/bobo')

Given('fresh command') do
  system("rake build") or raise "fails to build shard: $0"
end
