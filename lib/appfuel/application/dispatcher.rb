module Appfuel
  module Application
    module Dispatcher

      def dispatch(request, container)
        begin
          container[:feature_initializer].call(request.feature, container)
          action   = container[:action_loader].call(request.namespace, container)
          response = action.run(request.inputs)
        rescue Appfuel::Handler::HandlerFailure => e
          error_handler_key = :dispatcher_action_error_handler
          response = handle_exception(error_handler_key, e, container)
        rescue => e
          error_handler_key = :dispatcher_general_error_handler
          response = handle_exception(error_handler_key, e, container)
        end

        response
      end

      def handle_exception(error_handler_key, e, container)
        logger = container[:logger]
        load_error_handler(error_handler_key, container).call(e, logger)
        if error_handler_key == :dispatcher_action_error_handler
          return e.response
        end

        Appfuel::ResponseHandler.new.error(e)
      end

      def load_error_handler(key, container)
        handler = default_exception_handler
        if container.key?(key)
          handler = container[key]
        end
        handler
      end

      def default_exception_handler
        ->(e, logger = nil) {
          logger ||= Logger.new(STDOUT)
          logger.error "#{e.class.to_s} #{e.to_s} #{e.backtrace.join("\n")}"
        }
      end
    end
  end
end
