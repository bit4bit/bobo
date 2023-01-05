
module Bobo
  class Mob
    getter :id

    def initialize(@id : String)
      @resources = Hash(String, Resource).new()
    end

    def can_drive?(programmer : Programmer, resource : Resource)
      mob_resource = @resources.fetch(resource.id, nil)

      if mob_resource.nil?
        return Result.ok()
      else
        Result.fail("can't drive file example.rb mismatch content")
      end
    end

    def add_resource(resource : Resource)
      @resources[resource.id] = resource
    end

    def resource(id : String) : Resource?
      @resources.fetch(id, nil)
    end

    def resources_of_copilot(programmer : Programmer) : Resources
      @resources.values.reject do |resource|
        resource.programmer_id == programmer.id
      end
    end

    def release(programmer : Programmer, id : String)
      resource = @resources.fetch(id, nil)
      if resource.nil?
        Result.fail("resource not found")
      elsif resource.programmer_id == programmer.id
        @resources.delete(id)
        Result.ok()
      else
        Result.fail("programmer it's not driving the resource")
      end
    end

    def drive(programmer : Programmer, resource : Resource)
      result = can_drive?(programmer, resource)
      return result if result.fail?

      @resources[resource.id] = resource

      Result.ok()
    end
  end
end
