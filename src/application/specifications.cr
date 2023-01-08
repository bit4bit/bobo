module Bobo::Application
  class Specifications::AllowedContentSize < Specification(Bobo::Resource)
    def initialize(@max_size : Int32)
    end

    def isSatisfiedBy(expr): Bobo::Result
      if expr.content.bytesize > @max_size
        Bobo::Result.error("overflow max size")
      else
        Bobo::Result.ok(expr)
      end
    end
  end

  # Reglas que deben cumplir los recursos
  class ResourceSpecification < Specification(Bobo::Resource)
    def initialize
      @specifications = [] of Specification(Bobo::Resource)
    end

    def allowed_content_size=(max_size : Int32)
      @specifications << Specifications::AllowedContentSize.new(max_size)
    end

    def isSatisfiedBy(expr : Bobo::Resource) : Bobo::Result
      @specifications.each do |spec|
        result = spec.isSatisfiedBy(expr)
        return result if result.error?
      end
      Result.ok(expr)
    end
    def isSatisfiedBy(expr : IO::Memory) : Bobo::Result
      @specifications.each do |spec|
        result = spec.isSatisfiedBy(expr)
        return result if result.error?
      end
      Result.ok(expr)
    end

    def self.specification
      spec = new()
      yield spec
      spec
    end
  end
end
