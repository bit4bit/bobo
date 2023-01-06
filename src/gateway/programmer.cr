require "crest"

module Bobo
  module Gateway
    class Programmer
      alias Resources = Array(Bobo::Resource)

      getter :id

      def initialize(@id : String,
                     @mob_url : String,
                     @log : Log,
                     @mob_directory : String)
      end

      def file_hash(path : Path | String): String
        digest = Digest::SHA256.new
        digest.file(path)
        digest.hexfinal
      end

      def hash(data : String) : String
        digest = Digest::SHA256.new
        digest << data
        digest.hexfinal
      end

      def get(id : String) : Bobo::Programmer
        Bobo::Programmer.new(id)
      end

      def resources_of_copilot(mob_id : String, programmer_id : String) : Resources
        resources = Resources.new()
        url = "#{@mob_url}/#{mob_id}/#{programmer_id}/resources"
        resp = Crest.get(url, logging: false)
        if resp.status_code != 200
          @log.debug { "errors to get resources: #{resp.body}" }
          return resources
        end
        resp.body.lines.each do |resource_id|
          next if resource_id == ""
          @log.debug { "getting resource [#{resource_id}]" }

          url = "#{@mob_url}/#{mob_id}/resource"
          resp2 = Crest.get(url, headers: {"resource_id" => resource_id}, logging: false)
          if resp2.status_code != 200
            @log.error { "errors to pull #{resource_id}: #{resp.body}" }
            next
          end

          programmer_id = nil
          hash = nil
          relative_path = nil
          content = IO::Memory.new()
          resource_data = IO::Memory.new(resp2.body)
          HTTP::FormData.parse(resource_data, "boundary") do |part|
            case part.name
            when "programmer_id"
              programmer_id = part.body.gets_to_end
            when "relative_path"
              relative_path = part.body.gets_to_end
            when "id"
              resource_id = part.body.gets_to_end
            when "hash"
              hash = part.body.gets_to_end
            when "content"
              IO.copy(part.body, content)
            end
          end

          @log.debug { "pull resource #{resource_id} of programmer #{programmer_id}" }
          resources << Bobo::Resource.new(
            id: resource_id.not_nil!,
            programmer_id: programmer_id.not_nil!,
            relative_path: relative_path.not_nil!,
            hash: hash.not_nil!,
            content: content)
        end

        resources
      end

      def release(mob_id : String, programmer_id : String, resource_id : String) : Result
        url = "#{@mob_url}/#{mob_id}/drive/delete"

        resp = Crest.post(url, {"mob_id" => mob_id,
                                "programmer_id" => programmer_id,
                                "id" => resource_id})
        if resp.status_code == 200
          Bobo::Result.ok()
        else
          Bobo::Result.error(resp.body)
        end
      rescue ex : Crest::RequestErrored
        Bobo::Result.error(ex.response.body)
      end

      def drive(mob_id : String, resource : Bobo::Resource) : Bobo::Result
        url = "#{@mob_url}/#{mob_id}/drive"

        resp = Crest.post(
          url,
          {"content" => resource.content,
           "mob_id" => mob_id,
           "programmer_id" => resource.programmer_id,
           "id" => resource.id,
           "hash" => resource.hash,
           "relative_path" => resource.relative_path},
          logging: false
        )

        if resp.status_code == 200
          Bobo::Result.ok()
        else
          Bobo::Result.error(resp.body)
        end
      rescue ex : Crest::RequestFailed
        Bobo::Result.error(ex.response.body)
      end
    end
  end
end
