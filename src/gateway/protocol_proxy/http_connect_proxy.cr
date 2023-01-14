require "connect-proxy"

module Bobo::Gateway::ProtocolProxy
  class HTTPConnectProxy < ProtocolProxier

    @proxy : ConnectProxy

    def initialize(@tls : OpenSSL::SSL::Context::Client,
                   host : String,
                   port : Int32)
      @proxy = ConnectProxy.new(host, port)
    end

    def as_http_client(url : URI) : HTTP::Client
      client = ConnectProxy::HTTPClient.new(url, tls: @tls)
      client.set_proxy(@proxy)
      client
    end
  end
end
