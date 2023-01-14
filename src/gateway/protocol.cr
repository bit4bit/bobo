require "crest"
require "uri"
require "./protocol_proxy"
module Bobo::Gateway
  class Protocol
    alias Response = HTTP::Client::Response
    alias RequestFailed = Crest::RequestFailed

    def initialize(@ssl : OpenSSL::SSL::Context::Client,
                   @proxy : ProtocolProxier)
    end

    def create(url, form = {} of String => String) : Response
      uri = URI.parse(url)
      Crest.post(url, form,
                 http_client: @proxy.as_http_client(uri),
                 logging: false
                ).http_client_res
    end

    def read(url, headers = {} of String => String) : Response
      uri = URI.parse(url)
      Crest.get(url,
                headers: headers,
                logging: false,
                http_client: @proxy.as_http_client(uri),
               ).http_client_res
    end
  end
end
