module Appfuel
  module Validation
    class ValidatorPipe
      attr_reader :name, :dependencies, :code

      def initialize(name, dependencies = {}, &block)
        @code    = block
        @dependencies = dependencies
      end

      def pipe?
        true
      end

      def call(inputs, data = Dry::Container.new)
        code.call(inputs, data)
      end
    end
  end
end
