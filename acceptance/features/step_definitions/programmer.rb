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
    !@error.nil?
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
    @mob_pid = Process.spawn({"LOG_LEVEL" => "INFO"}, "#{$bin_path.join('bobo-mob')} test -d #{@mob_directory} -q -p #{@mob_http_port}")
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
  def initialize(id, mob_http_port, mob_directory, max_file_size: nil)
    @id = id
    @mob_directory = mob_directory
    @mob_http_port = mob_http_port
    @port = HTTPPorts.next
    @max_file_size = max_file_size
  end

  def start(mob_id)
    args = "-i #{mob_id} -u #{@id} -d #{@mob_directory} -q -p #{@port} -l https://localhost:#{@mob_http_port} -t 1"
    args += " --max-resource-content-size=#{@max_file_size}" if @max_file_size
    @mob_pid = Process.spawn({"LOG_LEVEL" => "INFO"}, "#{$bin_path.join('bobo-programmer')} #{args} ")
  end

  def mob_id
    RestClient.get("http://localhost:#{@port}/mobid").body
  end

  def handover(file)
    res = RestClient.post("http://localhost:#{@port}/handover",
                          {"filepath" => file})

    if res.code.to_i == 200
      Result.new(nil, res.body)
    else
      Result.new(res.body)
    end
  rescue RestClient::Exception => e
    Result.new(e.response.body)
  end

  def drive(file)
    res = RestClient.post("http://localhost:#{@port}/drive",
                          {"filepath" => file})

    if res.code.to_i == 200
      Result.new(nil, res.body)
    else
      Result.new(res.body)
    end
  rescue RestClient::Exception => e
    Result.new(e.response.body)
  end

  def drives()
    res = RestClient.get("http://localhost:#{@port}/drives")
    
    if res.code.to_i == 200
      drives = res.body.split("\n")
      Result.new(nil, drives)
    else
      Result.new(res.body)
    end
  rescue RestClient::Exception => e
    Result.new(e.response.body)
  end

  def project_file(name)
    File.join(@mob_directory, name)
  end
  private :project_file

  def modification_time(name)
    File.stat(project_file(name)).mtime
  end
  
  def content(path)
    File.read(project_file(path))
  end

  def write_content(path, content)
    File.write(project_file(path), content)
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

def a_source_code
  tmpdir = Pathname.new(Dir.tmpdir)
  path = tmpdir.join('source-code')
  FileUtils.mkdir_p(path)

  File.write(path.join('example.rb'), 'puts "hello"')
  File.write(path.join('example.sh'), 'echo "hello"')

  path
end

Given('the source code') do
  @project_dir = a_source_code()
end

Given('a partner') do
  project_dir = a_source_code()
  @partner = Programmer.new('partner', @mob.mob_http_port, project_dir)
  @partner.start(@mob.id)
  @partner.wait_started()
end

Given('the partner drive a file') do
  @partner.drive('example.rb')
end

When('I drive a file') do
  @result = @programmer.drive('example.rb')
end

When('I drive a big file') do
  @programmer.write_content('example.rb', 'XXX' * 1000000)

  @result = @programmer.drive('example.rb')
end

When('I handover the file') do
  @result = @programmer.handover('example.rb')
end

When('I drive a file using absolute path') do
  @programmer.drive('/example.rb')
end

When('I try to drive a file out of project') do
  @result = @programmer.drive('../example.rb')
end

Then('I can see the drived file') do
  result = @programmer.drives()
  fail("result fails") if result.error?

  expect(result.ok).to include('example.rb')
end

# NOTE: muy bonito esto, huele a que es necesario
# normalizar siempre la ruta relativa
Then('I can see the drived file using absolute path') do
  result = @programmer.drives()
  fail("result fails") if result.error?

  expect(result.ok).to include('/example.rb')
end

Then("I can't see the drived file") do
  result = @programmer.drives()
  fail("result fails") if result.error?

  expect(result.ok).to_not include('example.rb')
end

# OLD
When('I start mob') do
  @mob = Mob.new('test', @project_dir)
  @mob.start
  @mob.wait_started
end

Then('I connect to mob started') do
  @programmer = Programmer.new('test', @mob.mob_http_port, @project_dir)
  @programmer.start(@mob.id)
  @programmer.wait_started()

  expect(@programmer.mob_id).to eq(@mob.id)
end

Then('I connect to mob started with max-file-size {int} bytes') do |size|
  @programmer = Programmer.new('test', @mob.mob_http_port, @project_dir, max_file_size: size)
  @programmer.start(@mob.id)
  @programmer.wait_started()

  expect(@programmer.mob_id).to eq(@mob.id)
end

Then('I expect same content of drived partner file') do
  sleep 2

  file = 'example.rb'
  expect(@programmer.content(file)).to eq(@partner.content(file))
end

Then('I do not expect changes on the file') do
  sleep 2
  current_time = @programmer.modification_time('example.rb')
  sleep 3
  end_time = @programmer.modification_time('example.rb')

  expect(end_time).to eq(current_time)
end

Then('I handover file {string}') do |file|
  @result = @programmer.handover(file)
end

Then('fails with message {string}') do |msg|
  if @result.error? == false
    fail("expected fails")
  end

  expect(@result.error).to eq(msg)
end
