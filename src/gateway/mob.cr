module Bobo
  module Gateway
    class Mob
      getter :mob_directory

      def initialize
        @mobs = Hash(String, Bobo::Mob).new()
        @programmers = Hash(String, Bobo::Programmer).new()
      end

      def get_programmer(id : String) : Bobo::Programmer
        p = @programmers.fetch(id, nil)
        return p unless p.nil?

        p = Bobo::Programmer.new(id)
        @programmers[id] = p
        p
      end

      def get(id : String) : Bobo::Mob
        mob = @mobs.fetch(id, nil)
        return mob unless mob.nil?

        mob = Bobo::Mob.new(id)
        @mobs[id] = mob
        mob
      end

      def id : String
        @id
      end

      def sync(mob : Bobo::Mob)
      end
    end
  end
end
