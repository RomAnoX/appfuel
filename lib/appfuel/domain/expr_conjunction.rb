module Appfuel
  module Domain
    class ExprConjunction
      attr_reader :op, :left, :right

      def initialize(type, left, right)
        @op    = type.to_s.downcase
        @left  = left
        @right = right
      end
    end
  end
end
