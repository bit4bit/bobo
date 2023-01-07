module Bobo
  module Gateway
    class Hasher
      def self.file_hash(path : Path | String): String
        digest = Digest::SHA256.new
        digest.file(path.to_path)
        digest.hexfinal
      end

      def self.hash(data : String) : String
        digest = Digest::SHA256.new
        digest << data
        digest.hexfinal
      end
    end
  end
end
