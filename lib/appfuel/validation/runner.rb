module Appfuel
  module Validation
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
    class Runner
      # Ensures inputs are valid or that its ok to use the raw inputs.
      # It will return a failed response object when validation fails
      # and a successful response with the valid inputs inside ok.
      #
      # NOTE: When no validators are declared inputs are forced to an
      #       empty hash. If you want raw inputs you must use the
      #       skip_validation interface in the ValidatorDependency mixin.
      #
      # collect all errors under one key until a fail fast is found or the
      # end is reached
      #
      # @param inputs [Hash] raw inputs to be validated
      # @return [Response]
      def call(validators, container, inputs = {})
        response = nil
        has_failed = false
        validators.each do |validator|
          fail_fast = data[:fail_fast] || false
          if validator.pipe?
            result = handle_validator_pipe(validator, inputs)
            inputs = result unless result == false
            next
          end

          result = validator.call(inputs)
          if result.success? && !has_failed
            response = handle_successful_inputs(result, response)
            next
          end

          return error(result.errors(full: true)) if fail_fast
          has_failed = true
          response = handle_error_inputs(result, response)
        end

        fail "multi validators can not be only Procs" if response.nil?

        response
      end

      private

      def handle_successful_inputs(result, response)
        if response.nil?
          ok(result.output)
        else
          ok(response.ok.merge(result.output))
        end
      end

      def handle_error_inputs(result, response)
        if response.nil?
          error(result.errors(full: true))
        else
          error(result.errors(full: true).merge(response.error_messages))
        end
      end

      def handle_validator_pipe(pipe, inputs)

        result = pipe.call(inputs, inject_pipe_dependencies)
        return false unless result
        unless result.is_a?(Hash)
          fail "multi validator proc must return a Hash"
        end
        result
      end

      def inject_pipe_dependencies
        container = Dry::Container.new
        app_container = Appfuel.container

        container.register(:repo_runner, app_container[:repo_runner])
        container
      end
    end
  end
end
