module Bobo::Gateway
  abstract class ProtocolProxier
    abstract def as_http_client(url : URI) : HTTP::Client
  end
end

require "./protocol_proxy/http_ssl_proxy"  
require "./protocol_proxy/http_connect_proxy"  
