module Appfuel
  module Predicates
    include Dry::Logic::Predicates

    predicate(:criteria?) do |value|
      value.instance_of?(Appfuel::Criteria)
    end

  end
end
