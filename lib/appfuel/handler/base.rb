module Appfuel
  module Handler
    class Base
      extend ValidatorDsl
      extend InjectDsl
      include Appfuel::Application::AppContainer

      # Class level interfaces used by the framwork to register and run
      # handlers
      class << self

        # Register the extending class with the application container
        #
        # @param klass [Class] the handler class that is inheriting this
        # @return nil
        def inherited(klass)
          register_container_class(klass)
        end

        def response_handler
          @response_handler ||= ResponseHandler.new
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
            return response if response.failure?
            valid_inputs = response.ok

            resolve_dependencies(container)
            handler = self.new(container)
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

      def ok(value = nil)
        self.class.ok(value)
      end

      def error(*args)
        self.class.error(*args)
      end

      def present(name, data, inputs = {})
        return data if inputs[:raw] == true

        key = qualify_container_key(name, 'presenters')
        container = self.class.app_container
        unless container.key?(key)
          unless data.respond_to?(:to_h)
            fail "data must implement :to_h for generic presentation"
          end

          return data.to_h
        end

        container[key].call(data, inputs)
      end
    end
  end
end
