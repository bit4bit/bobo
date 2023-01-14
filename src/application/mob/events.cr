module Bobo::Application::Events
  alias Event = ResourceDrived

  class ResourceDrived
    include JSON::Serializable

    property metadata : Bobo::ResourceMetadata

    def initialize(@metadata : Bobo::ResourceMetadata)
    end

    def self.from(resource : Bobo::Resource)
      new(resource.metadata)
    end

    def self.from_wire(data : String) : self
      new(Bobo::ResourceMetadata.from_wire(data))
    end

    def to_wire : String
      @metadata.to_wire
    end
  end
end
