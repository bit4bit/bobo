require "crest"


module Bobo::Gateway
  class Protocol
    alias Response = Crest::Response
    alias RequestFailed = Crest::RequestFailed

    def initialize(@ssl : OpenSSL::SSL::Context::Client,
                   @socks_port : Int32? = nil)
    end

    def create(url, form = {} of String => String) : Response
      if !@socks_port.nil?
        Crest.post(url, form,
                   tls: @ssl,
                   logging: false,
                   p_addr: "127.0.0.1",
                   p_port: @socks_port.not_nil!)
      else
        Crest.post(url, form, tls: @ssl, logging: false)
      end
    end

    def read(url, headers = {} of String => String) : Response
      if !@socks_port.nil?
        Crest.get(url, headers: headers,
                  logging: false,
                  tls: @ssl,
                  p_addr: "127.0.0.1",
                  p_port: @socks_port.not_nil!)
      else
        Crest.get(url, headers: headers, logging: false, tls: @ssl)
      end
    end
  end
end
