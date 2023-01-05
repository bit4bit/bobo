module Bobo
  class ToxRpc::Server < ServerRpc
    @tox : LibTox::Tox
    class Context
      getter :arguments

      def initialize
        @arguments = Hash(String, String).new()
        @arguments["id"] = "123"
      end
    end

    def address
      address = Pointer(UInt8).malloc(LibTox.address_size())
      LibTox.self_get_address(@tox, address)
      Tox::Utils.bin_to_hex(address, LibTox.address_size())
    end

    def iterate
      @poll.iterate(@tox)
      sleep LibTox.iteration_interval(@tox).millisecond
    end

    def handle(name : String, &handler :  (Request -> Reply))

    end

    def bootstrap
      [
        ["85.172.30.117", 33445, "8E7D0B859922EF569298B4D261A8CCB5FEA14FB91ED412A7603A585A25698832"],
        ["85.143.221.42", 33445, "DA4E4ED4B697F2E9B000EEFE3A34B554ACD3F45F5C96EAEA2516DD7FF9AF7B43"]
      ].each do |node|
        host = node[0].as(String)
        port = node[1].as(Int32)
        public_key = node[2].as(String)

        tox_bootstrap(host, port, public_key)
      end

      Log.debug { "bootstraped" }
    end

    private def tox_bootstrap(host, port, public_key)
      key = Tox::PublicKey.new(public_key)
      LibTox.bootstrap(@tox, host, port, key, out err)
      Tox::Error.raise_if(err)
    end


    def listen
      loop do
        select
        when ev = @poll.event(Tox::Event::FriendConnection, 1.hour).receive
          Log.debug { "update status connection for friend #{ev.friend_number} #{ev.status}" }
        when ev = @poll.event(Tox::Event::Message, 1.hour).receive
          msg = String.new(ev.message)

          Log.debug { "received message #{msg}" }
        when ev = @poll.event(Tox::Event::FriendRequest, 1.hour).receive
          friend_number = LibTox.friend_add_norequest(@tox, ev.public_key, out err)
          Tox::Error.raise_if(err)
          @friends_number << friend_number

          msg = "hola"
          LibTox.friend_send_message(@tox, friend_number, LibTox::MessageType::MessageTypeNormal, msg.to_slice(), msg.bytesize, nil)

          Log.debug { "added friend #{friend_number}" }
        when ev = @poll.event(Tox::Event::Connection, 1.hour).receive
          Log.debug { "updated status connection #{ev.status}" }
        end
      end
    end

    def initialize(@log : Log)
      @friends_number = [] of UInt32

      @poll = Tox::Event::Poller.new(512, events: [
                                       Tox::Event::FriendRequest,
                                       Tox::Event::FriendConnection,
                                       Tox::Event::Message,
                                       Tox::Event::Connection
                                     ])
      @tox = LibTox.new(nil, out err)
      Tox::Error.raise_if(err)

      @poll.install(@tox)
    end

  end
end
