module Appfuel
  module ViewModel
    # View Models are very basic, they take an entity, value object, or
    # any other dataset and convert it into the final hash that can than
    # be turned into json or serialized how ever you want. The view models
    # themselves are not classes, but rather, just blocks of code whose
    # context is changed to this class once executed.
    class Base
      attr_reader :finder

      # The finder is required because this class does not have access to
      # the root module or feature module required for looking up models.
      #
      # @param finder [lamda] used to locate other view models
      # @return [Base]
      def initialize(finder)
        @finder = finder
      end

      # Use the finder to locate the view model then call it
      #
      # @param dataset [entity, collection, any data]
      # @param inputs [Hash] used to control view model
      # @return Hash
      def present(dataset, inputs = {})
        model = finder.call(dataset, inputs)
        model.call(dataset, inputs)
      end
    end
  end
end
