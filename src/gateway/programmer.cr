require "./programmer/event_provider"

module Bobo
  module Gateway
    class Programmer
      alias Resources = Array(Bobo::Resource)
      alias ResourcesMetadata = Array(Bobo::ResourceMetadata)
      getter :id

      def initialize(@mob_url : String,
                     @log : Log,
                     @mob_directory : String,
                     @protocol : Bobo::Gateway::Protocol,
                     @hasher = Bobo::Gateway::Hasher.new)
      end

      def get(id : String) : Bobo::Programmer
        Bobo::Programmer.new(id)
      end

      def resource(mob_id : String, resource_id : String) : Bobo::Result
          url = "#{@mob_url}/#{mob_id}/resource"
          resp = @protocol.read(url, headers: {"resource_id" => resource_id})
          if resp.status_code != 200
            return Result.error("errors getting resource #{resource_id}: #{resp.body}")
          end

          metadata = nil
          content = IO::Memory.new()
          resource_data = IO::Memory.new(resp.body)
          HTTP::FormData.parse(resource_data, "boundary") do |part|
            case part.name
            when "metadata"
              metadata = Bobo::ResourceMetadata.from_wire(part.body.gets_to_end)
            when "content"
              IO.copy(part.body, content)
            end
          end

          r = Bobo::Resource.new(
            id: metadata.not_nil!.id,
            programmer_id: metadata.not_nil!.programmer_id,
            relative_path: Path[metadata.not_nil!.relative_path],
            hash: metadata.not_nil!.hash,
            content: content)
          Result.ok(r)
      end

      def resources_of_copilot(mob_id : String, programmer_id : String) : ResourcesMetadata
        resources = ResourcesMetadata.new()

        url = "#{@mob_url}/#{mob_id}/#{programmer_id}/resources"
        resp = @protocol.read(url)
        if resp.status_code != 200
          @log.debug { "errors to get resources: #{resp.body}" }
          return resources
        end

        resp.body.lines.each do |metadata_raw|
          metadata = Bobo::ResourceMetadata.from_wire(metadata_raw)
          next if metadata.id == ""
          resources << metadata
        end

        resources
      end

      def handover(mob_id : String, programmer_id : String, resource_id : String) : Result
        url = "#{@mob_url}/#{mob_id}/drive/delete"

        resp = @protocol.create(url, {"mob_id" => mob_id,
                                     "programmer_id" => programmer_id,
                                     "id" => resource_id})
        if resp.status_code == 200
          Bobo::Result.ok()
        else
          Bobo::Result.error(resp.body)
        end
      rescue ex : Protocol::RequestFailed
        Bobo::Result.error(ex.response.body)
      end

      def drive(mob_id : String, resource : Bobo::Resource) : Bobo::Result
        url = "#{@mob_url}/#{mob_id}/drive"

        resp = @protocol.create(
          url,
          {"content" => resource.content,
           "mob_id" => mob_id,
           "programmer_id" => resource.programmer_id,
           "id" => resource.id,
           "hash" => resource.hash,
           "relative_path" => resource.relative_path.to_s}
        )

        if resp.status_code == 200
          Bobo::Result.ok()
        else
          Bobo::Result.error(resp.body)
        end
      rescue ex : Protocol::RequestFailed
        Bobo::Result.error(ex.response.body)
      end
    end
  end
end
