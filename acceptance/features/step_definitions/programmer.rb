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

  def write_content(path, content)
    File.write(File.join(@mob_directory, path), content)
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

Then('I connect to mob started with max-file-size {int} bytes') do |size|
  @programmer = Programmer.new('test', @mob.mob_http_port, @project_dir, max_file_size: size)
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
  if @result.error? != false
    fail(@result.error)
  end
end


Then('connect partner {string} in {string}') do |name, project|
  project_dir = @projects_dir.fetch(project)
  partner = Programmer.new(name, @mob.mob_http_port, project_dir)
  partner.start(@mob.id)
  partner.wait_started()

  @partners ||= {}
  @partners[name] = partner
end

Then('partner {string} drive file {string}') do |name, file|
  partner = @partners.fetch(name)
  result = partner.drive(file)
  expect(result.error?).to be false
end

Then('I wait {int} second') do |int|
  sleep int
end

Then('In {string} file {string} expects content {string}') do |project, file, content|
  project_dir = @projects_dir.fetch(project)
  Dir.chdir(project_dir) do |path|
    filename = File.join(path, file)
    fail("not file #{path} in project #{project}") unless File.exists?(filename)
    got_content = File.read(filename)
    
    expect(got_content).to eq(content)
  end
end

Then('I handover file {string}') do |file|
  @result = @programmer.handover(file)
end

Then('ok') do
  if @result.error? != false
    fail("expected ok")
  end
end

Then('fails with message {string}') do |msg|
  if @result.error? == false
    fail("expected fails")
  end

  expect(@result.error).to eq(msg)
end

Then('I wait {int} seconds and in {string} file {string} is the same') do |wait, project, file|
  project_dir = @projects_dir.fetch(project)
  project_file = File.join(project_dir, file)
  current_time = File.stat(project_file).mtime
  sleep wait
  end_time = File.stat(project_file).mtime

  expect(end_time).to eq(current_time)
end

