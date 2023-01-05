require "tox"

module Bobo
  class ToxRpc::Client < ClientRpc
    @tox : LibTox::Tox

    def address
      address = Pointer(UInt8).malloc(LibTox.address_size())
      LibTox.self_get_address(@tox, address)
      Tox::Utils.bin_to_hex(address, LibTox.address_size())
    end

    def iterate
      @poll.iterate(@tox)
      sleep LibTox.iteration_interval(@tox).millisecond
    end

    def bootstrap
      [
        ["85.172.30.117", 33445, "8E7D0B859922EF569298B4D261A8CCB5FEA14FB91ED412A7603A585A25698832"]
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
        when ev = @poll.event(Tox::Event::Message, 1.hour).receive
          msg = String.new(ev.message)
          Log.debug { "received message #{msg}" }
        when ev = @poll.event(Tox::Event::FriendConnection, 1.hour).receive
          Log.debug { "update status connection for friend #{ev.friend_number} #{ev.status}" }
        when ev = @poll.event(Tox::Event::Connection, 1.hour).receive
          connect_to(@mob_address.not_nil!)
          Log.debug { "updated self connection status #{ev.status}" }
        end
      end
    end

    def call(name : String, args : Rpc::Request) : Rpc::Reply
      Rpc::Reply.new()
    end

    def connect(address : Address)
      @mob_address = address
    end

    private def connect_to(address : Address)
      message = "toxrpc"

      friend_number = LibTox.friend_add(@tox, address, message.to_slice(), message.bytesize, out err)
      Tox::Error.raise_if(err)

      @friends_number << friend_number

      Log.debug { "added friend #{address.to_s}" }
    end

    def initialize(@log : Log)
      @mob_address = nil
      @friends_number = [] of UInt32
      @poll = Tox::Event::Poller.new(512, events: [
                                       Tox::Event::FriendConnection,
                                       Tox::Event::Connection,
                                       Tox::Event::Message
                                     ])
      @tox = LibTox.new(nil, out err)
      Tox::Error.raise_if(err)

      @poll.install(@tox)
    end
  end
end
