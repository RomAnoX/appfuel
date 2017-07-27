module Appfuel
  module Handler
    class HandlerFailure < StandardError
      attr_reader :response
      def initialize(msg = "Unknown handler error", response)
        @response = response
        super(msg)
      end
    end
  end
end
