module Bobo
  alias Resources = Array(Resource)

  class Resource
    def initialize(
         id : String,
         relative_path : Bobo::Path,
         programmer_id : String,
         hash : String,
         content : IO)
      @metadata = ResourceMetadata.new(
        id: id,
        relative_path: relative_path.to_path.to_s,
        programmer_id: programmer_id,
        hash: hash)
      content.seek(0)
      @content = IO::Memory.new()
      IO.copy(content, @content)
      @content.seek(0)
    end

    def id
      @metadata.id
    end
    def relative_path
      Bobo::Path[@metadata.relative_path]
    end
    def programmer_id
      @metadata.programmer_id
    end
    def hash
      @metadata.hash
    end

    def content
      @content.dup
    end

    def self.from_file(id : String, programmer_id : String, hash : String, path : Path, relative_path : String) : Resource
      content = IO::Memory.new()
      File.open(path.to_path, "r") do |f|
        IO.copy(f, content)
      end

      resource = new(id: id,
                     relative_path: Path[relative_path],
                     programmer_id: programmer_id,
                     hash: hash,
                     content: content)
    end


  end
end
