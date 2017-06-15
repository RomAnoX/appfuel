module Appfuel
  module Application
    module Dispatcher

      def dispatch(request, container)
        begin
          container[:feature_initializer].call(request.feature, container)
          action   = container[:action_loader].call(request.namespace, container)
          response = action.run(request.inputs)
        rescue => e
          handler = Appfuel::ResponseHandler.new
          response = handler.error(e)
        end

        response
      end
    end
  end
end
