module Appfuel
  module Application
    module Dispatcher

      def dispatch(request, container)
        begin
          container[:feature_initializer].call(request.feature, container)
          action   = container[:action_loader].call(request.namespace, container)
          response = action.run(request.inputs)
        rescue Appfuel::Handler::HandlerFailure => e
          response = e.response
        rescue => e
          handler = Appfuel::ResponseHandler.new
          response = handler.error(e)
        end

        response
      end
    end
  end
end
