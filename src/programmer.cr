module Bobo
  class Programmer
    getter :id

    def initialize(@id : String)
    end

    class Error < Exception
    end
  end
end
