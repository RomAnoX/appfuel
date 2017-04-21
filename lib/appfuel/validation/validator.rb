module Appfuel
  module Validation
    # Any validator that is run for an action or command will be created with
    # this class. It service to abstract away Dry::Validation, the library we
    # use from the system that runs all the validators. This allows us to use
    # validators along side things like validator pipes without the system
    # having to care.
    class Validator
      attr_reader :name, :schema

      # @param name [String] used to register this validator in a container
      # @param schema [Dry::Validation::Schema] the actual validator
      # @param fail_fast [Bool] tell the system how to fail
      # @return [Validator]
      def initialize(name, schema, fail_fast: false)
        @name = name
        unless schema.respond_to?(:call)
          fail ArgumentError, "schema must implement :call"
        end
        @schema = schema

        fail_fast == true ? enable_fail_fast : disable_fail_fast
      end

      # Ensures the system will stop validating when this validator fails
      #
      # @return [Bool]
      def enable_fail_fast
        @fail_fast = true
      end

      # Ensures the system will continue validating when errors exist
      #
      # @return [Bool]
      def disable_fail_fast
        @fail_fast = false
      end

      # @return [Bool]
      def fail_fast?
        @fail_fast
      end


      # Delegate's to the Dry::Validation schema to validate the inputs
      #
      # @param inputs [Hash]
      # @return [Dry::Validation::Result]
      def call(inputs)
        schema.call(inputs)
      end

      # Tell this system this is not a validation pipe
      def pipe?
        false
      end
    end
  end
end
