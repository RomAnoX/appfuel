module Appfuel
  module Application
    module Dispatcher

      def dispatch(request, container)
        begin
          container[:feature_initializer].call(request.feature, container)
          action = container[:action_loader].call(request.namespace, container)
          response = action.run(inputs)
        rescue => e
          handler_error(e, container)
        end

        if response.failure?
          handle_error(contaier,  :failed, error)
        end
      end

      private
      def handle_error(e, container)
        unless container.key?(:error_handler)
          return default_error_handling(e, contianer) unless container.key?(:error_handler)
        end

      end

      def default_error_handling(e, container)

      end
    end
  end
end
