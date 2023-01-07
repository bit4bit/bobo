task "bin/bobo" => FileList.new('src/*.cr') do
  sh "shards build"
end

task :build => ["bin/bobo"] do
end

task :prod do
  sh "docker run -t --rm -v $PWD:/usr/src -w /usr/src crystallang/crystal:1.6-alpine sh -c 'shards build --production --static'"
end
