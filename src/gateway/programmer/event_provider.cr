require "http/web_socket"
require "uri"

module Bobo::Gateway
  class ProgrammerEventProvider
    alias EventHandler = (String, Bobo::Application::Events::Event) -> Void

    def initialize(@mob_url : String, @mob_id : String, @tls : OpenSSL::SSL::Context::Client)
      @handlers = Array(EventHandler).new
      uri = URI.parse(@mob_url)
      port = uri.port
      port ||= 80
      @ws = HTTP::WebSocket.new(uri.host.not_nil!, "/#{@mob_id}/events", port, tls: @tls)

      @ws.on_message do |msg|
        event = Bobo::Gateway::Event.from_wire(msg)
        @handlers.each do |handler|
          handler.call(event.tag, event.event)
        end
      end
    end

    def on_event(&handler : EventHandler)
      @handlers << handler
    end

    def run
      @ws.run
    end
  end
end
