module Bobo
  class Tor
    class Config
      @tor_binary_path : String? = nil
      @mob_http_port : Int32 = 0
      @socks_port : Int32? = nil
      @http_tunnel_port : Int32? = nil
      @torrc_path : String? = nil
      @tor_working_dir : String? = nil
      @tor_process : Process? = nil
      @tor_onion : Bool = false
      @tor_alias : String = "server"
      @retries = 6

      property :mob_http_port
      property :tor_binary_path
      property :socks_port
      property :http_tunnel_port
      property :torrc_path
      property :tor_working_dir
      property :tor_onion
      property :tor_alias
      property :retries

      def create_torrc()
        File.open(torrc_path.not_nil!, "w", perm: 0o700) do |f|
          if tor_onion
            f.puts "HiddenServiceDir #{tor_working_dir}"
            f.puts "HiddenServicePort 443 127.0.0.1:#{mob_http_port}"
          end
          f.puts "SocksPort #{socks_port.not_nil!}"
          f.puts "HTTPTunnelPort #{http_tunnel_port.not_nil!}"
        end
        FileUtils.mkdir_p(tor_working_dir.not_nil!, mode: 0o700)
      end

      def print_banner()
        if tor_onion
          hostname_path = File.join(tor_working_dir.not_nil!, "hostname")
          hostname = File.read(hostname_path)
          puts "+-------------------------------------------+\n"
          puts "BOBO: mob server url https://#{hostname}"
          puts "+-------------------------------------------+\n\n"
        else
          puts "+-------------------------------------------+\n"
          puts "BOBO: tor client started"
          puts "+-------------------------------------------+\n\n"
        end
      end

      def defaults()
        self.torrc_path ||= File.join(Dir.tempdir, "bobo-#{self.tor_alias}-tor.torrc")
        self.tor_working_dir ||= File.join(Dir.tempdir, "bobo-#{self.tor_alias}-tor-working")
        self.tor_binary_path ||= Process.find_executable("tor")
        self.socks_port ||= Config.ephemeral_port()
        self.http_tunnel_port ||= Config.ephemeral_port()
      end

      def self.ephemeral_port(): Int32
        server = TCPServer.new("localhost", 0)
        port = server.local_address.port
        server.close

        port
      end
    end

    class Server
      def self.run
        config = Config.new
        yield config

        config.defaults()

        srv = new(config)
        srv.start
        srv.wait
      end

      def initialize(@config : Config)
      end

      def start
        abort "not found tor binary please use --tor-binary-path" if !File.executable?(@config.tor_binary_path.not_nil!)

        @config.create_torrc()
        output = IO::Memory.new()

        @tor_process = Process.new(
          @config.tor_binary_path.not_nil!, ["-f", @config.torrc_path.not_nil!],
          output: IO::MultiWriter.new(STDOUT, output),
          clear_env: true,
          env: {"HOME" => @config.tor_working_dir.not_nil!}
        )

        wait_tor_bootstrapped(output)
        @config.print_banner()
      end

      def wait
        @tor_process.not_nil!.wait
      end

      private def wait_tor_bootstrapped(output : IO)
        @config.retries.times.each do |_|
          return if output.to_s.includes?("Bootstrapped 100%")
          sleep 10.seconds
        end
        abort "fails to run tox"
      end
    end
  end
end
