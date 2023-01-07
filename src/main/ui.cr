class UI
  def initialize(@pgapp : Bobo::Application::Programmer, @programmer_url : String, @mob_directory : String, @log : Log)
    @drives = Set(String).new()
  end

  def browser(env)
    directory = env.params.query.fetch("directory", nil)
    up_directory = @mob_directory
    up_directory = Path[directory].parent.relative_to(@mob_directory).normalize.to_s if !directory.nil?
    directory = @mob_directory if [".", ".."].includes?(directory)
    directory ||= @mob_directory

    names = Dir.children(directory).map do |name|
      relname = Path[directory].join(name).relative_to(@mob_directory).normalize.to_s
      if File.directory?(name)
        {relname, :directory}
      else
        {relname, :file}
      end
    end.reject {|n| @drives.includes?(n[0]) }

    render "src/ui/views/index.html.ecr"
  end

  def action_drive(env)
    filepath = env.params.body["filepath"].as(String)

    begin
      resp = Crest.post("#{@programmer_url}/drive", {"filepath" => filepath})
      if resp.status_code == 200
        @drives.add(filepath)
      end
    rescue ex : Crest::RequestFailed
      @log.error { ex.message }
    end

    browser(env)
  end

  def action_release(env)
    filepath = env.params.body["filepath"].as(String)

    begin
      resp = Crest.post("#{@programmer_url}/drive/delete", {"filepath" => filepath})
      if resp.status_code == 200
        @drives.delete(filepath)
      end
    rescue ex : Crest::RequestFailed
      @log.error { ex.message }
    end

    browser(env)
  end

  def install(mob_id : String, programmer_id : String, iteration_interval)
    spawn do
      loop do
        @pgapp.copilot(mob_id.not_nil!, programmer_id.not_nil!)
        sleep iteration_interval.second
      rescue ex : Exception
        @log.error { ex.inspect_with_backtrace }
        sleep 15.second
      end
    end
  end
end
