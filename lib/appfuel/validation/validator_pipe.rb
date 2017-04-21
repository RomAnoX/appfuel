module Appfuel
  module Validation
    # A pipe is just a lambda that take two arguments. It is designed to
    # live between two validators in an array and maninuplate the output
    # of the first validator to satisfy the secord. It is needed when
    # you want to use two reusable validators that don't quite work
    # togather.
    class ValidatorPipe
      attr_reader :name, :dependencies, :code

      #
      # @param name [String] key used for errors & containers
      # @param dependencies [Hash] for dependency injection
      # @return [ValidatorPipe]
      def initialize(name, dependencies = {}, &block)
        @code    = block
        @dependencies = dependencies
      end

      # Because validator and pipe live togather in the same array. The
      # system runner needs to be able to tell them apart.
      #
      # @return [TrueCase]
      def pipe?
        true
      end

      # Delegate call to the actual pipe lambda
      #
      # @param inputs [Hash]
      # @param data [Dry::Container] dependency injection container
      # @return [Hash] new inputs for the next validator
      def call(inputs, data = Dry::Container.new)
        code.call(inputs, data)
      end
    end
  end
end
