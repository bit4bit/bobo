require "spec"
require "../src/bobo"

def make_tmpdir(name = "temp_test") : Path
  suffix = Time.utc.nanosecond

  path = Path[Dir.tempdir].join("#{name}.#{suffix}")
  Dir.mkdir_p(path)

  path
end
