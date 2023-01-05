
task "bin/bobo" => FileList.new('src/*.cr') do
  sh "shards build"
end

task :build => ["bin/bobo"] do
end
