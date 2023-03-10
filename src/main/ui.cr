class UI
  def initialize(
    @mob_id : String,
    @programmer_id : String,
    @pgapp : Bobo::Application::Programmer,
    @pggw : Bobo::Gateway::Programmer,
    @programmer_url : String,
    @mob_directory : String,
    @log : Log,
    @drives : Set(String)
  )
  end

  def browser(env)
    directory = env.params.query.fetch("directory", nil) || env.params.body.fetch("directory", nil) || env.params.query.fetch("directory", nil)
    up_directory = @mob_directory
    up_directory = Path[directory].parent.relative_to(@mob_directory).normalize.to_s if !directory.nil?
    directory = "" if [".", ".."].includes?(directory)
    directory ||= ""

    workspace = Path[@mob_directory].join(directory)
    names = Dir.children(workspace).map do |name|
      relname = workspace.join(name).relative_to(@mob_directory).normalize.to_s
      abspath = workspace.join(name)
      if File.directory?(abspath)
        {relname, :directory}
      else
        {relname, :file}
      end
    end.reject { |n| @drives.includes?(n[0]) }.sort_by { |n| n[0] }

    copiloting_resources = @pggw.resources_of_copilot(@mob_id, @programmer_id)

    render "src/ui/views/index.html.ecr"
  end

  def action_drive(env)
    directory = env.params.body.fetch("directory", ".")
    filepath = env.params.body["filepath"].as(String)

    begin
      resp = Crest.post("#{@programmer_url}/drive", {"filepath" => filepath})
    rescue ex : Crest::RequestFailed
      @log.error { ex.message }
    end

    env.redirect "/ui?directory=#{directory}"
  end

  def action_handover(env)
    directory = env.params.body.fetch("directory", ".")
    filepath = env.params.body["filepath"].as(String)

    begin
      resp = Crest.post("#{@programmer_url}/handover", {"filepath" => filepath})
    rescue ex : Crest::RequestFailed
      @log.error { ex.message }
    end

    env.redirect "/ui?directory=#{directory}"
  end
end
