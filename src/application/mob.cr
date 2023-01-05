module Bobo
  module Application
    class Mob
      def initialize(@gateway : Gateway::Mob)
      end

      def get_id
        @gateway.id
      end
    end
  end
end
