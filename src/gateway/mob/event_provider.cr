require "http/web_socket"

module Bobo::Gateway
  class MobEventProvider < Bobo::Application::MobEventProvider
    alias WebSockets = Array(HTTP::WebSocket)

    def initialize
      @subscribers = {} of String => WebSockets
    end

    def handle(mob_id : String, event : Bobo::Application::Events::ResourceDrived)
      @subscribers[mob_id] ||= WebSockets.new()
      @subscribers[mob_id].each do |socket|
        next if socket.closed?
        socket.send Bobo::Gateway::Event.create("resource-drived", event).to_wire
      end
    end

    def subscribe_websocket(mob_id : String, websocket : HTTP::WebSocket)
      @subscribers[mob_id] ||= WebSockets.new()
      @subscribers[mob_id] << websocket
    end
  end
end
