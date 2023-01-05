module Bobo
  abstract class Rpc
    alias Request = Hash(String, String)
    alias Reply = Hash(String, String)
  end

  abstract class ClientRpc < Rpc
    abstract def call(name : String, args : Request) : Reply
  end

  abstract class ServerRpc < Rpc
    abstract def handle(name : String, &handler : (Request -> Reply))
  end
end
