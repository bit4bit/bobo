

module Bobo
  class Programmer
    getter :id

    def initialize(@id : String)
    end

    def mob_id : String
      @mob.id
    end

    class Error < Exception
    end
  end
end
