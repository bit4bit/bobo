module Bobo
  class Result(Ok, Error)
    getter :ok

    def initialize(@error : Error = nil, @ok : Ok = nil)
    end

    def self.error(error : Error)
      new(error, nil)
    end

    def self.ok(ok : Ok = "Ok")
      new(nil, ok)
    end

    def ok? : Bool
      !@ok.nil?
    end

    def error? : Bool
      !@error.nil?
    end

    def error : Error
      @error
    end
  end
end
