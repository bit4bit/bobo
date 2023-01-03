module Bobo
  class Programmer
    getter :mob_id

    def initialize(@mob_id : String, @mob_directory : String)
    end

    def self.connect(mob_id : String, directory : String) : Programmer
      new(mob_id, directory)
    end

  end
end
