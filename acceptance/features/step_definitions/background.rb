require 'rake/file_utils'

$bin_path = Pathname.new(File.absolute_path('../bin'))

system("rake build") or raise "fails to build shard: $0"
