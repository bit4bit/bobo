require "http/client"

module Bobo::Gateway::ProtocolProxy
  class HTTPSSLProxy < ProtocolProxier
    def initialize(@tls : HTTP::Client::TLSContext)
    end

    def as_http_client(url : URI) : HTTP::Client
      HTTP::Client.new(url, @tls)
    end
  end
end
