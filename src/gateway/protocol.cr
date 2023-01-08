require "crest"
require "uri"
require "connect-proxy"

module Bobo::Gateway
  class Protocol
    alias Response = HTTP::Client::Response
    alias RequestFailed = Crest::RequestFailed

    @proxy : ConnectProxy? = nil

    def initialize(@ssl : OpenSSL::SSL::Context::Client,
                   @http_tunnel_port : Int32? = nil)

      if @http_tunnel_port
        @proxy = ConnectProxy.new("127.0.0.1", @http_tunnel_port.not_nil!)
      end
    end

    def create(url, form = {} of String => String) : Response
      if !@proxy.nil?
        uri = URI.parse(url)
        client = ConnectProxy::HTTPClient.new(uri)
        client.set_proxy(@proxy.not_nil!)
        Crest.post(url, form,
                   http_client: client,
                   tls: @ssl,
                   logging: false).http_client_res
      else
        Crest.post(url, form, tls: @ssl, logging: false).http_client_res
      end
    end

    def read(url, headers = {} of String => String) : Response
      if !@proxy.nil?
        uri = URI.parse(url)
        client = ConnectProxy::HTTPClient.new(uri)
        client.set_proxy(@proxy.not_nil!)

        Crest.get(url,
                  headers: headers,
                  logging: false,
                  tls: @ssl,
                  http_client: client
                  ).http_client_res
      else
        Crest.get(url, headers: headers, logging: false, tls: @ssl).http_client_res
      end
    end
  end
end
