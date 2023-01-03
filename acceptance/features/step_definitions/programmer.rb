require 'rest-client'
require 'singleton'

class HTTPPorts
  include Singleton

  @@port = 63100

  def self.next
    @@port += 1
    @@port
  end
end

class Mob
  def initialize
    @mob_http_port = HTTPPorts.next
  end

  def start
    @mob_pid = Process.spawn("#{$command_path} mob-start -q --port #{@mob_http_port}")
  end

  def id
    res = RestClient.get("http://localhost:#{@mob_http_port}/id")
    res.body
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
  def initialize
    @mob_http_port = HTTPPorts.next
  end

  def start(mob_id)
    @mob_pid = Process.spawn("#{$command_path} programmer -i #{mob_id} -q --port #{@mob_http_port}")
  end

  def mob_id
    RestClient.get("http://localhost:#{@mob_http_port}/mobid").body
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
end

When('I start mob') do
  @mob = Mob.new
  @mob.start
  @mob.wait_started
end

Then('I can query mob ID') do
  expect(@mob.id).to match(/^[0-9a-fA-Z]+$/)
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

Then('I can connect to mob started') do
  programmer = Programmer.new()
  programmer.start(@mob.id)
  programmer.wait_started()
  expect(programmer.mob_id).to eq(@mob.id)
end

