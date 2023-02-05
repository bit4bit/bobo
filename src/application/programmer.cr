require "log"
require "file_utils"

module Bobo
  module Application
    class Programmer
      def initialize(@gateway : Gateway::Programmer,
                     @log : Log,
                     @resource_constraints : ResourceConstraints,
                     mob_directory : String)
        @drives = Set(String).new

        @mob_directory = Path[::Path[mob_directory].expand]
      end

      def copiloting_resource(mob_id : String, metadata : Bobo::ResourceMetadata) : Bobo::Result
        resource_path = @mob_directory.join(metadata.relative_path).to_path
        resource_dirname = ::Path[resource_path].dirname

        # mismo hash omitimos sincronizacion
        return Result.error("same file") if file_has_hash(resource_path, metadata.hash)
        return Result.error("drived resource") if is_driving(metadata.relative_path)

        result = @gateway.resource(mob_id, metadata.id)
        return result if result.error?
        resource = result.ok.not_nil!

        FileUtils.mkdir_p(resource_dirname)
        File.open(resource_path, "w") do |f|
          IO.copy(resource.content, f)
        end
        @log.debug { "updated resource id: #{resource.id}" }

        Result.ok(resource)
      end

      def copiloting(mob_id : String, programmer_id : String)
        resources_metadata = @gateway.resources_of_copilot(mob_id, programmer_id)
        resources_metadata.each do |metadata|
          result = copiloting_resource(mob_id, metadata)
          next if result.error?
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
        result = @resource_constraints.verify(resource)
        return result if result.error?

        result = @gateway.drive(mob_id, resource)
        @drives.add(path) if result.ok?
        result
      rescue ex : Error
        Result.error(ex.message)
      end

      private def is_driving(relative_path : String) : Bool
        @drives.includes?(relative_path)
      end

      private def resource_id(path : Path | String) : String
        Gateway::Hasher.hash(path)
      end

      private def file_has_hash(path : ::Path | String, hash : String) : Bool
        File.exists?(path) && Gateway::Hasher.file_hash(Path[path]) == hash
      end
    end
  end
end
