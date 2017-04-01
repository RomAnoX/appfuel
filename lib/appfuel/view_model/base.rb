module Appfuel
  module ViewModel
    class Base
      attr_reader :finder
      def initialize(finder)
        @finder = finder
      end

      def present(entity, inputs = {})
        model = finder.call(entity, inputs)
        model.call(entity, inputs)
      end
    end
  end
end
