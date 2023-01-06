require "ecr/macros"

class SSLMemory
  @key_mem : IO::Memory
  @cert_mem : IO::Memory

  getter :key_path
  getter :cert_path

  def initialize()
    @key_mem = IO::Memory.new()
    @cert_mem = IO::Memory.new()

    ECR.embed "server.key", @key_mem
    ECR.embed "server.crt", @cert_mem

  end

  def key_path
    name = File.tempname(".bobo-key", ".ssl")
    File.open(name, "w") do |f|
      IO.copy(@key_mem, f)
    end
    @key_mem.seek(0)
    name
  end

  def cert_path
    name = File.tempname(".bobo-cert", ".ssl")
    File.open(name, "w") do |f|
      IO.copy(@cert_mem, f)
    end
    @cert_mem.seek(0)
    name
  end

end
