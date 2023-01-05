require 'json'
require 'rest-client'
require 'singleton'

class Result
  attr_reader :ok
  attr_reader :error

  def initialize(error = nil, ok = nil)
    @ok = ok
    @error = error
  end

  def error?
    !@result.nil?
  end
end

class HTTPPorts
  include Singleton

  @@port = 63100

  def self.next
    @@port += 1
    @@port
  end
end

class Mob
  attr_reader :mob_http_port
  attr_reader :id

  def initialize(id, mob_directory)
    unless mob_directory
      raise "expected mob_directory"
    end
    @id = id
    @mob_directory = mob_directory
    @mob_http_port = HTTPPorts.next
  end

  def start
    @mob_pid = Process.spawn({"LOG_LEVEL" => "DEBUG"}, "#{$bin_path.join('bobomob')} test -d #{@mob_directory} -q --port #{@mob_http_port}")
  end


  def wait_started
    sleep 1
  end

  def stop
    Process.kill(9, @mob_pid)
    Process.wait @mob_pid
  end
end

class Programmer
  def initialize(id, mob_http_port, mob_directory)
    @id = id
    @mob_directory = mob_directory
    @mob_http_port = mob_http_port
    @port = HTTPPorts.next
    
  end

  def start(mob_id)
    @mob_pid = Process.spawn({"LOG_LEVEL" => "DEBUG"}, "#{$bin_path.join('boboprogrammer')} -i #{mob_id} -u #{@id} -d #{@mob_directory} -q --port #{@port} -l http://localhost:#{@mob_http_port}")
  end

  def mob_id
    RestClient.get("http://localhost:#{@port}/mobid").body
  end

  def drive(file)
    res = RestClient.post("http://localhost:#{@port}/drive",
                          {"filepath" => file})

    if res.code.to_i == 200
      Result.new(ok: res.body)
    else
      Result.new(res.body)
    end
  rescue RestClient::InternalServerError => e
    Result.new(e.response.body)
  rescue RestClient::ServiceUnavailable => e
    Result.new(e.response.body)
  end

  def stop
    Process.kill(9, @mob_pid)
    Process.wait @mob_pid
  end

  def wait_started
    sleep 1
  end
end

After do |scenario|
  if !@mob.nil?
    @mob.stop
  end

  if !@programmer.nil?
    @programmer.stop
  end
  system("pkill -9 bobo")
end

When('I start mob') do
  @mob = Mob.new('test', @project_dir)
  @mob.start
  @mob.wait_started
end

Then('I can query mob ID') do
  expect(@mob.id).to match(/^[0-9a-zA-Z]+$/)
end

Given('example source code as {string}') do |name|
  tmpdir = Pathname.new(Dir.tmpdir)
  path = tmpdir.join(name)
  FileUtils.mkdir_p(path)

  File.write(path.join('example.rb'), 'puts "hello"')
  File.write(path.join('example.sh'), 'echo "hello"')

  @projects_dir ||= {}
  @projects_dir[name] = path
end


Given('I inside {string}') do |project|
  @project_dir = @projects_dir.fetch(project)
end

Given('In {string} file {string} has content {string}') do |project, file, content|
  dir = @projects_dir.fetch(project)
  path = File.join(dir, file)
  File.write(path, content)
end

Then('I connect to mob started') do
  @programmer = Programmer.new('test', @mob.mob_http_port, @project_dir)
  @programmer.start(@mob.id)
  @programmer.wait_started()

  expect(@programmer.mob_id).to eq(@mob.id)
end

Then('I drive file {string}') do |file|
  @result = @programmer.drive(file)
end

Then('drive fails with error message {string}') do |msg|
  expect(@result.error?).to be true
  expect(@result.error).to eq(msg)
end

Then('drive ok') do
  expect(@result.error?).to be false
end

