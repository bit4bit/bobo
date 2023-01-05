module Bobo
  module Application
    class Programmer
      def initialize(@mob_provider : MobProvider,
                     @programmer_provider : ProgrammerProvider,
                     mob_directory : String)
        @mob_directory = Path[mob_directory]
      end

      def get_mob_id(mob_id : String)
        mob = @mob_provider.get(mob_id).not_nil!
        mob.id
      end

      def drive(mob_id : String, programmer_id : String, path : String) : Result
        mob = @mob_provider.get(mob_id).not_nil!
        programmer = @programmer_provider.get(programmer_id)
        programmer_resource = Resource.from_file(mob, programmer, @mob_directory.join(path))
        mob_resource = @mob_provider.get_resource(programmer_resource.id)

        result = mob.can_drive?(programmer, programmer_resource, mob_resource)
        return result if result.fail?

        result = programmer.drive(mob, programmer_resource)
        return result if result.fail?

        @mob_provider.sync(mob)

        result
      end
    end

    class Mob
      def initialize(@mob_provider : MobProvider)
      end

      def get_id
        @mob_provider.id
      end
    end
  end
end
