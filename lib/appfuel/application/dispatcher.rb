module Appfuel
  module Application
    module Dispatcher

      def dispatch(request, container)
        begin
          container[:feature_initializer].call(request.feature, container)
          action = container[:action_loader].call(request.namespace, container)
          response = action.run(request.inputs)
        rescue => e
          handle_error(e, container)
        end

        if response.failure?
          handle_error(contaier,  :failed, error)
        end
      end

      private
      def handle_error(e, container)
        p e.message
        p e.backtrace
      end

      def default_error_handling(e, container)

      end
    end
  end
end
