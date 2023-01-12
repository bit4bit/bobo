require "http/web_socket"

module Bobo::Gateway
  class MobNotification < Bobo::Application::MobNotification
    alias WebSockets = Array(HTTP::WebSocket)

    def initialize
      @subscribers = {} of String => WebSockets
    end


    def resourceDrived(mob_id : String, resource : Bobo::Resource)
      @subscribers[mob_id] ||= WebSockets.new()
      @subscribers[mob_id].each do |socket|
        next if socket.closed?
        event = Bobo::Gateway::Event.create(Bobo::Application::Events::ResourceDrived.from(resource))
        socket.send event.to_wire
      end
    end

    def subscribe_websocket(mob_id : String, websocket : HTTP::WebSocket)
      @subscribers[mob_id] ||= WebSockets.new()
      @subscribers[mob_id] << websocket
    end
  end
end
