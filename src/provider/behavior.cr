abstract class Bobo::MobProvider
  abstract def id() : String
  abstract def get(id : String) : Bobo::Mob
  abstract def sync(mob : Bobo::Mob)
  abstract def get_resource(id : String) : Bobo::Resource?
end
