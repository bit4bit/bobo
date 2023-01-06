require "ecr/macros"

class SSLMemoryClient
  @cert_mem : IO::Memory

  getter :cert_path

  def initialize()
    @cert_mem = IO::Memory.new()

    ECR.embed "server.crt", @cert_mem
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
