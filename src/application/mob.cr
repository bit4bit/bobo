require "./mob/events"

module Bobo
  module Application
    class MobNotification
      def resourceDrived(mob_id : String, event : Bobo::Resource)
      end
    end

    class Mob
      def initialize(@gateway : Gateway::Mob,
                     @resource_constraints : Bobo::Application::ResourceConstraints,
                     @notification = MobNotification.new())
      end

      def get_id
        @gateway.id
      end

      def drive(mob_id : String, resource : Resource) : Bobo::Result
        result = @resource_constraints.verify(resource)
        return result if result.error?

        mob = @gateway.get(mob_id)
        programmer = @gateway.get_programmer(resource.programmer_id)

        result = mob.drive(programmer, resource)

        if result.ok?
          @notification.resourceDrived(mob_id, resource)
        end
        result
      end

      def handover(mob_id : String, programmer_id : String, resource_id : String) : Bobo::Result
        mob = @gateway.get(mob_id)
        programmer = @gateway.get_programmer(programmer_id)

        mob.handover(programmer, resource_id)
      end
    end
  end
end
