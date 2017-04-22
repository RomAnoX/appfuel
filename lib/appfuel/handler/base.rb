module Appfuel
  module Handler

    # The handler is responsible for logic involved when an Action or a Command
    # is run. There are two ways to execute a handler:
    #   1) using its call interface
    #   example:
    #     handler = Handler.new
    #     handler.call(inputs, dependency_injection)
    #
    #   2) using its class level run interface example)
    #   example:
    #     Handler.run(inputs)
    #
    class Base
      extend ValidatorDsl
      extend InjectDsl

      #extend RepositoryInjectionDsl
      #extend ContainerInjectionDsl
      #extend CommandInjectionDsl
      #extend DomainInjectionDsl
      #
      class << self
        def response_handler
          @response_handler ||= ResponseHandler.new
        end

        def feature_key
          parts = self.to_s.split('::')
          feature_name = parts[1].underscore
          "features.#{feature_name}"
        end

        # Resolve dependencies for this handler into a container that will
        # later be injected into the handlers initializer
        #
        # @param  results  [Dry::Container] dependency injection container
        # @return [Dry::Container]
        def resolve_dependencies(results = Dry::Container.new)
          #results.register(:criteria_class, criteria_class)
          #results
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
