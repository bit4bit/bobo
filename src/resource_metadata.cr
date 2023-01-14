require "json"

module Bobo
  class ResourceMetadata
    # aaa impuro :)
    include JSON::Serializable

    property id : String
    property relative_path : String
    property programmer_id : String
    property hash : String

    def initialize(@id : String,
                   @relative_path : String,
                   @programmer_id : String,
                   @hash : String)
    end

    def self.from_resource(resource : Bobo::Resource)
      new(id: resource.id,
        relative_path: resource.relative_path.to_path.to_s,
        programmer_id: resource.programmer_id,
        hash: resource.hash)
    end

    def initialize(@id : String,
                   @relative_path : String,
                   @programmer_id : String,
                   @hash : String)
    end

    def self.from_wire(data : String) : self
      self.from_json(data)
    end

    def to_wire : String
      self.to_json
    end
  end
end
