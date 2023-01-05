module Bobo
  alias Resources = Array(Resource)

  class Resource
    getter :id
    getter :relative_path
    getter :programmer_id
    getter :hash

    def initialize(
         @id : String,
         @relative_path : String,
         @programmer_id : String,
         @hash : String,
         content : IO)
      content.seek(0)
      @content = IO::Memory.new()
      IO.copy(content, @content)
      @content.seek(0)
    end

    def content
      @content.dup
    end

    def self.from_file(id : String, programmer_id : String, hash : String, path : Path, relative_path : String)
      if !File.exists?(path)
        raise "not found file #{path}"
      end

      content = IO::Memory.new()
      File.open(path, "r") do |f|
        IO.copy(f, content)
      end

      new(id: id,
          relative_path: relative_path,
          programmer_id: programmer_id,
          hash: hash,
          content: content)
    end
  end
end
