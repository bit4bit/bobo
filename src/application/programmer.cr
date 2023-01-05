require "log"

module Bobo
  module Application
    class Programmer
      def initialize(@gateway : Gateway::Programmer,
                     @log : Log,
                     mob_directory : String)
        @mob_directory = Path[mob_directory]
      end

      def synchronize_with_mob(mob_id : String, programmer_id : String)
        resources = @gateway.resources_of_copilot(mob_id, programmer_id)
        resources.each do |resource|
          @log.debug { "updating resource id: #{resource.id} to #{resource.relative_path} of programmer #{programmer_id}" }
          resource_path = @mob_directory.join(resource.relative_path)
          File.open(resource_path, "w") do |f|
            IO.copy(resource.content, f)
          end
          @log.debug { "updated resource id: #{resource.id}" }
        end
      end

      def get_mob_id(mob_id : String)
        mob_id
      end

      def drive(mob_id : String, programmer_id : String, path : String) : Result
        resource = Resource.from_file(programmer_id, @mob_directory.join(path), relative_path: path)

        result = @gateway.drive(mob_id, resource)
        result
      end
    end
  end
end
