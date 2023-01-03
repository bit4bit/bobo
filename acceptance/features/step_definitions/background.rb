require 'rake/file_utils'

fail 'not found command' unless File.exists?('../bin/bobo')

$command_path = File.absolute_path('../bin/bobo')

Given('fresh command') do
  %x{cd ../ && shards build}
end
