module Appfuel
  module Repository
    class ExprConjunction
      OPERATORS = ['and', 'or'].freeze
      attr_reader :op, :left, :right

      def initialize(type, left, right)
        @op    = validate_operator(type)
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

      private
      def validate_operator(type)
        type = type.to_s.downcase
        unless OPERATORS.include?(type)
          fail "Conjunction operator can only be (and|or)"
        end
        type
      end
    end
  end
end
