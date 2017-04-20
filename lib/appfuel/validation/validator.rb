module Appfuel
  module Validation
    class Validator
      attr_reader :name, :schema

      def initialize(name, schema, fail_fast: false)
        @name   = name
        @schema = schema
        fail_fast == true ? enable_fail_fast : disable_fail_fast
      end

      def enable_fail_fast
        @fail_fast = true
      end

      def disable_fail_fast
        @fail_fast = false
      end

      def fail_fast?
        @fail_fast
      end

      def call(inputs)
        schema.call(inputs)
      end

      def pipe?
        false
      end
    end
  end
end
