module Bobo::Application
  # Reglas que deben cumplir los recursos
  class ResourceConstraints
    setter :allowed_content_size

    def initialize
      @allowed_content_size = 1024 * 300
    end

    def verify(resource : Bobo::Resource) : Bobo::Result
      if resource.content.bytesize > @allowed_content_size
        Result.error("overflow max size")
      else
        Result.ok(resource)
      end
    end

    def self.constraints
      spec = new()
      yield spec
      spec
    end
  end
end
