module Bobo
  module Application
    class Mob
      def initialize(@gateway : Gateway::Mob,
                     @resource_constraints : Bobo::Application::ResourceConstraints)
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
      end
    end
  end
end
