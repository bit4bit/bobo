class UI
  def initialize(@pgapp : Bobo::Application::Programmer, @programmer_url : String, @mob_directory : String, @log : Log)
    @drives = Set(String).new()
  end

  def browser(env)
    directory = env.params.query.fetch("directory", nil) || env.params.body.fetch("directory", nil) || env.params.query.fetch("directory", nil)
    up_directory = @mob_directory
    up_directory = Path[directory].parent.relative_to(@mob_directory).normalize.to_s if !directory.nil?
    directory = @mob_directory if [".", ".."].includes?(directory)
    directory ||= @mob_directory

    workspace = Path[@mob_directory].join(directory)
    names = Dir.children(workspace).map do |name|
      relname = workspace.join(name).relative_to(@mob_directory).normalize.to_s
      abspath = workspace.join(name)
      if File.directory?(abspath)
        {relname, :directory}
      else
        {relname, :file}
      end
    end.reject {|n| @drives.includes?(n[0]) }.sort_by { |n| n[0] }

    render "src/ui/views/index.html.ecr"
  end

  def action_drive(env)
    directory = env.params.body.fetch("directory", ".")
    filepath = env.params.body["filepath"].as(String)

    begin
      resp = Crest.post("#{@programmer_url}/drive", {"filepath" => filepath})
      if resp.status_code == 200
        @drives.add(filepath)
      end
    rescue ex : Crest::RequestFailed
      @log.error { ex.message }
    end

    env.redirect "/ui?directory=#{directory}"
  end

  def action_handover(env)
    directory = env.params.body.fetch("directory", ".")
    filepath = env.params.body["filepath"].as(String)

    begin
      resp = Crest.post("#{@programmer_url}/drive/delete", {"filepath" => filepath})
      if resp.status_code == 200
        @drives.delete(filepath)
      end
    rescue ex : Crest::RequestFailed
      @log.error { ex.message }
    end

    env.redirect "/ui?directory=#{directory}"
  end
end
