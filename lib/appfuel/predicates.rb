module Appfuel
  module Predicates
    include Dry::Logic::Predicates

    predicate(:criteria?) do |value|
      value.instance_of?(Appfuel::Domain::Criteria)
    end

  end
end
