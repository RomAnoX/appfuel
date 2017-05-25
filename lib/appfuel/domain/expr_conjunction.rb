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

      def qualified?
        left.qualified? && right.qualified?
      end

      def qualify_feature(feature, domain)
        left.qualify_feature(feature, domain) unless left.qualified?
        right.qualify_feature(feature, domain) unless right.qualified?
      end

      def qualify_global(domain)
        left.qualify_global(domain) unless left.qualified?
        right.qualify_global(domain) unless right.qualified?
      end
    end
  end
end
