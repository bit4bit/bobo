module Bobo
  class Resource
    getter :id
    def initialize(
         @id : String,
         @mob : Mob,
         @programmer : Programmer,
         @content_hash : String)
    end

    def self.from_file(mob : Mob, programmer : Programmer, path : Path)
      if !File.exists?(path)
        raise "not found file #{path}"
      end

      hash = digest_file(path)
      new(path.to_s, mob, programmer, hash)
    end

    private def self.digest_file(file : String | Path) : String

      digest = Digest::SHA256.new
      digest.file(file)
      digest.hexfinal
    end
  end
end
