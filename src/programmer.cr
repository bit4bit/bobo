module Bobo
  class Programmer
    getter :mob_id

    def initialize(@mob_id : String, @mob_directory : String, @provider : Provider)
    end

    def drive(path : String)
      raise "can't drive file example.rb mismatch content"
    end

    def self.connect(mob_id : String, directory : String, provider : Provider) : Programmer
      new(mob_id, directory, provider)
    end

  end
end
