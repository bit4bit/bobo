

module Bobo
  class Programmer

    def initialize(@id : String, mob_directory : String)
      @mob_directory = Path[mob_directory]
    end

    def mob_id : String
      @mob.id
    end

    def drive(mob : Mob, resource : Resource) : Result
      mob.add_resource(resource)

      Result.ok()
    end

    class Error < Exception
    end
  end
end
