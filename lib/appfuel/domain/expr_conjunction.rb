module Appfuel
  module Domain
    class ExprConjunction
      attr_reader :op, :left, :right

      def initialize(type, left, right)
        @op    = type.to_s.downcase
        @left  = left
        @right = right
      end

      def conjunction?
        true
      end

      def qualify_feature(feature, domain)
        left.qualify_feature(feature, domain)
        right.qualify_feature(feature, domain)
      end

      def qualify_global(domain)
        left.qualify_global(domain)
        right.qualify_global(domain)
      end
    end
  end
end
