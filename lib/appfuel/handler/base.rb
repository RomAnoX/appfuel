module Appfuel
  module Handler
    class Base
      extend ValidatorDsl
      extend InjectDsl
      extend Appfuel::Application::ContainerKey

      class << self
        def inherited(klass)
          root = klass.container_root_key
          return if root == 'appfuel'

          container = Appfuel.app_container(root)
          container.register(klass.qualified_handler_key, klass)
        end

        def response_handler
          @response_handler ||= ResponseHandler.new
        end

        def handler_key
          @handler_key ||= container_path_list[2..-1].join('.')
        end

        def qualified_handler_key
          @qualified_handler_key ||= "#{feature_key}.#{handler_key}"
        end

        # Run will validate all inputs; returning on input failures, resolving
        # declared dependencies, then delegate to the handlers call method with
        # its valid inputs and resolved dependencies. Finally it ensure every
        # response is a Response object.
        #
        # @param inputs [Hash] inputs to be validated
        # @return [Response]
        def run(inputs = {}, container = Dry::Container.new)
          begin
            response = resolve_inputs(inputs)
            ap 'validator response'
            return response if response.failure?
            valid_inputs = response.ok

            dependencies = resolve_dependencies(container)
            handler = self.new(dependencies)
            result = handler.call(valid_inputs)
            result = create_response(result) unless response?(result)
          rescue RunError => e
            result = e.response
          rescue StandardError => e
            result = error(e)
          end

          result
        end

        def error(*args)
          response_handler.error(*args)
        end

        def ok(value = nil)
          response_handler.ok(value)
        end

        def response?(value)
          response_handler.response?(value)
        end

        def create_response(data)
          response_handler.create_response(data)
        end

      end

      attr_reader :data

      def initialize(container = Dry::Container.new)
        @data = container
      end

      def call(inputs, data = {})
        fail "Concrete handlers must implement their own call"
      end
    end
  end
end
