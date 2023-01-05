module Bobo
  module Application
    class Programmer
      def initialize(@gateway : Gateway::Programmer,
                     mob_directory : String)
        @mob_directory = Path[mob_directory]
      end

      def get_mob_id(mob_id : String)
        mob_id
      end

      def drive(mob_id : String, programmer_id : String, path : String) : Result
        programmer = @gateway.get(programmer_id)
        resource = Resource.from_file(programmer, @mob_directory.join(path))

        result = @gateway.drive(mob_id, resource)
        result
      end
    end
  end
end
