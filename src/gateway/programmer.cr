require "crest"

module Bobo
  module Gateway
    class Programmer
      getter :id

      def initialize(@id : String,
                     @mob_url : String,
                     @mob_directory : String)
      end

      def get(id : String) : Bobo::Programmer
        Bobo::Programmer.new(id)
      end

      def drive(mob_id : String, resource : Bobo::Resource) : Bobo::Result
        url = "#{@mob_url}/#{mob_id}/drive"
        resp = Crest.post(
          url,
          {"resource" => resource.content,
           "mob_id" => mob_id,
           "programmer_id" => resource.programmer_id,
           "resource_id" => resource.id,
           "resource_hash" => resource.hash}
        )

        if resp.status_code == 200
          Bobo::Result.ok()
        else
          Bobo::Result.fail(resp.body)
        end
      end
    end
  end
end
