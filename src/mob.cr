
module Bobo
  class Mob
    getter :id

    def initialize(@id : String)
      @resources = Hash(String, Resource).new()
    end

    def can_drive?(programmer : Programmer, programmer_resource : Resource, mob_resource : Resource?)
      if mob_resource.nil?
        return Result.ok()
      else
        Result.fail("can't drive file example.rb mismatch content")
      end
    end

    def add_resource(resource : Resource)
      @resources[resource.id] = resource
    end

    def get_resource(id : String) : Resource?
      @resources.fetch(id, nil)
    end

    def drive(programmer : Programmer, path : String)
      Result.ok()
    end

    def content_hash(path : String | Path) : String
      @provider.digest_file(path)
    end
  end
end
