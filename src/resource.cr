module Bobo
  class Resource
    getter :id
    getter :programmer
    getter :content
    getter :hash

    def initialize(
         @id : String,
         @programmer : Programmer,
         @hash : String,
         @content : IO)
    end

    def programmer_id : String
      @programmer.id
    end

    def self.from_file(programmer : Programmer, path : Path)
      if !File.exists?(path)
        raise "not found file #{path}"
      end
      content = IO::Memory.new()
      File.open(path, "r") do |f|
        IO.copy(f, content)
      end

      hash = digest_file(path)
      new(path.to_s,programmer, hash, content)
    end

    private def self.digest_file(file : String | Path) : String

      digest = Digest::SHA256.new
      digest.file(file)
      digest.hexfinal
    end
  end
end
