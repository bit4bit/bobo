require "log"

require "tox"
require "./rpc"
require "./toxrpc/client"
require "./toxrpc/server"

module Bobo
  class ToxRpc::Address
    def initialize(@toxid : String)
    end

    def to_s
      @toxid
    end

    def to_unsafe
      Tox::Utils.hex_to_bin(@toxid)
    end
  end
end
