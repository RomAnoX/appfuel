require 'parslet'

module Appfuel
  module Domain
    # A PEG (Parser Expression Grammer) transformer for our domain language.
    #
    class ExprTransform < Parslet::Transform
      rule(op: simple(:x)) { ap 'i am an op'; x.strip }
    end
  end
end
