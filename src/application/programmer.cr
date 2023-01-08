require "log"
require "file_utils"

module Bobo
  module Application
    class Programmer
      def initialize(@gateway : Gateway::Programmer,
                     @log : Log,
                     mob_directory : String)
        @drives = Set(String).new()

        @mob_directory = Path[mob_directory]
      end

      def copiloting(mob_id : String, programmer_id : String)
        resources = @gateway.resources_of_copilot(mob_id, programmer_id)
        resources.each do |resource|
          resource_path = @mob_directory.join(resource.relative_path).to_path
          resource_dirname = ::Path[resource_path].dirname
          @log.debug { "updating resource id: #{resource.id} to #{resource_path} in #{resource_dirname} of programmer #{programmer_id}" }

          FileUtils.mkdir_p(resource_dirname)

          next if is_same_file(resource_path, resource)

          File.open(resource_path, "w") do |f|
            IO.copy(resource.content, f)
          end
          @log.debug { "updated resource id: #{resource.id}" }
        end
      end

      def get_mob_id(mob_id : String)
        mob_id
      end

      def handover(mob_id : String, programmer_id : String, path : String) : Result
        # force synchronization of driving resource
        drive(mob_id, programmer_id, path)

        id = resource_id(path)
        result = @gateway.handover(mob_id, programmer_id, id)
        @drives.delete(path) if result.ok?
        result
      end

      def driving(mob_id : String, programmer_id : String)
        @drives.each do |drive_path|
          drive(mob_id, programmer_id, drive_path)
        end
      end

      def drive(mob_id : String, programmer_id : String, path : String) : Result
        local_path = @mob_directory.join(path)
        return Result.error("not found file") unless File.exists?(local_path.to_path)

        hash = Gateway::Hasher.file_hash(local_path)
        resource = Resource.from_file(
          id: resource_id(path),
          programmer_id: programmer_id,
          hash: hash,
          path: local_path,
          relative_path: path)

        result = @gateway.drive(mob_id, resource)
        @drives.add(path) if result.ok?
        result
      rescue ex : Error
        Result.error(ex.message)
      end

      private def resource_id(path : Path | String) : String
        Gateway::Hasher.hash(path)
      end

      private def is_same_file(path : ::Path | String, resource : Resource) : Bool
        File.exists?(path) && Gateway::Hasher.file_hash(Path[path]) == resource.hash
      end
    end
  end
end
