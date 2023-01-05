require "tox"
require "digest"
require "digest/sha256"
require "./provider/behavior"

module Bobo
  class ProgrammerProvider
    getter :id

    def initialize(@id : String, @mob_directory : String)
    end

    def get(id : String) : Programmer
      Programmer.new(id, @mob_directory)
    end
  end

  class MobProvider::Local < MobProvider
    getter :mob_directory

    def initialize(@id : String, @mob_directory : String)
      @resources = [] of Resource
    end

    def create : Mob
      Mob.new(@id)
    end

    def add_resource(resource : Resource)
      @resources << resource
    end

    def get_resource(id : String) : Resource?
      @resources.find{|r| r.id == id}
    end

    def get(id : String) : Mob
      Mob.new(id)
    end

    def id : String
      @id
    end

    def sync(mob : Mob)
    end
  end

  class MobProvider::Remote < MobProvider::Local
    def initialize(@id : String, @mob_directory : String, @rpc : ClientRpc)
      super(@id, @mob_directory)
    end
  end
end
