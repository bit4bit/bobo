module Bobo::Application
  abstract class Specification(T)
    abstract def isSatisfiedBy(expr : T): Bobo::Result
  end
end

require "./specifications"
