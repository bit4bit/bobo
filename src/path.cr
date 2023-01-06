module Bobo
  # Esto es intencional intentamos evitar acceder a directorios fuera del proyecto
  class Path
    getter :path

    def initialize(@path : ::Path | String)
      must_be_valid_path(@path)
    end

    def self.[](name : String | ::Path) : Path
      new(name)
    end

    def join(part : self): Path
      Bobo::Path.new(::Path[self.path].join(part.path))
    end
    def join(part : String): Path
      Bobo::Path.new(::Path[self.path].join(part))
    end

    def to_path : ::Path
      ::Path[self.path]
    end

    def to_s
      @path.to_s
    end

    private def must_be_valid_path(path : ::Path | String)
      if !path.to_s.matches?(/^\/*[0-9a-zA-z\/]+/)
        raise Bobo::Error.new("invalid path")
      end
    end
  end
end
