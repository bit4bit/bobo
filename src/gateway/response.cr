require "json"

module Bobo::Gateway
  class Event
    getter :tag
    getter :event

    private def initialize(@tag : String, @event : Bobo::Application::Events::Event)
    end

    def self.create(tag, event : Bobo::Application::Events::Event)
      raise ArgumentError.new("event not responds to to_wire") unless event.responds_to?(:to_wire)

      new(tag, event)
    end

    def to_wire : String
      {"tag" => @tag,
       "event" => @event.to_wire}.to_json
    end

    def self.from_wire(wire : String) : self
      data = Hash(String, String).from_json(wire)
      tag = data["tag"].not_nil!
      case tag
      when "resource-drived"
        ev = Bobo::Application::Events::ResourceDrived.from_wire(data["event"].not_nil!.to_s)
        new(tag, ev)
      else
        raise "not known how to parse #{tag}"
      end
    end
  end
end
