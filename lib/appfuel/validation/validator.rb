module Appfuel
  module Validation
    class Validator
      attr_reader :name, :schema

      def initialize(name, schema, fail_fast: false)
        @schema    = schema
        @fail_fast = fail_fast == true ? true : false
      end

      def fail_fast?
        @fail_fast
      end

      def call(inputs)
        schame.call(inputs)
      end

      def pipe?
        false
      end
    end
  end
end
