module Bobo
  class Result(Ok, Fail)
    getter :ok
    def initialize(@fail : Fail = nil, @ok : Ok = nil)
    end

    def self.fail(error : Fail)
      new(error, nil)
    end

    def self.ok(ok : Ok = "Ok")
      new(nil, ok)
    end

    def fail? : Bool
      !@fail.nil?
    end

    def error : Fail
      @fail
    end
  end
end
