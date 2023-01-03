require 'rest-client'

When('I start mob') do
  @mob_http_port = 63100
  @mob_pid = Process.spawn("#{$command_path} mob-start --port #{@mob_http_port}")
end

Then('I stop mob') do
  Process.kill("KILL", @mob_pid)
  Process.wait @mob_pid
end

Then('I can query mob ID') do
  res = RestClient.get("http://localhost:#{@mob_http_port}/id")
  expect(rest.body.size).to eq(83)
end


Given('example source code as {string}') do |name|
  tmpdir = Pathname.new(Dir.tmpdir)
  path = tmpdir.join(name)
  FileUtils.mkdir_p(path)

  File.write(path.join('example.rb'), 'puts "hello"')
  File.write(path.join('example.sh'), 'echo "hello"')

  @projects_dir ||= {name => tmpdir}
end


Given('I inside {string}') do |project|
  @project_dir = @projects_dir.fetch(project)
end
