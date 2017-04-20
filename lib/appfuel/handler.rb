module Appfuel
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
  class Handler
    extend Validation::HandlerDsl


    class << self
      attr_writer :response_handler

      def response_handler
        @response_handler ||= ResponseHandler.new
      end

      def type(name)
        Types[name]
      end

      # Resolve dependencies for this handler into a container that will
      # later be injected into the handlers initializer
      #
      # @param  results  [Dry::Container] dependency injection container
      # @return [Dry::Container]
      def resolve_dependencies(results = Dry::Container.new)
        criteria_class = resolve_container_item(:criteria_class)
        results.register(:criteria_class, criteria_class)
        results
      end

      def build_handler(container = Dry::Container.new)
        self.new(container)
        #self.new(resolve_dependencies(container))
      end

      # Run will validate all inputs; returning on input failures, resolving
      # declared dependencies, then delegate to the handlers call method with
      # its valid inputs and resolved dependencies. Finally it ensure every
      # response is a Response object.
      #
      # @param inputs [Hash] inputs to be validated
      # @return [Response]
      def run(inputs = {})
        begin
          response = resolve_inputs(inputs)
          ap 'validator response'
          return response if response.failure?
          valid_inputs = response.ok

          result = build_handler.call(valid_inputs)
          ap 'building the handler'
          ap result
          result = create_response(result) unless response?(result)
        rescue RunError => e
          result = e.response
        rescue StandardError => e
          result = error(e)
        end

        result
      end

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
      def resolve_inputs(inputs = {})
        return ok(inputs) if skip_validation?
        return ok({}) unless validators?

        response = nil
        has_failed = false
        validators.each do |data|
          validator = data[:validator]
          fail_fast = data[:fail_fast] || false
          if validator.is_a?(Proc)
            result = handle_proc_for_inputs(validator, inputs)
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

      def handle_proc_for_inputs(callable, inputs)

        result = callable.call(inputs, inject_proc_dependencies)
        return false unless result
        unless result.is_a?(Hash)
          fail "multi validator proc must return a Hash"
        end
        result
      end

      def inject_proc_dependencies
        fail "top module must be a Module" unless top_module.is_a?(Module)

        container = Dry::Container.new
        app_container = top_module.container

        container.register(:repo_runner, app_container[:repo_runner])
        container
      end
    end

    attr_reader :data

    def initialize(container = Dry::Container.new)
      @data = container
    end


    def criteria_class
      @criteria_class ||= data[:criteria_class]
    end

    def build_criteria(entity_key, repo = nil, **opts)
      constructor_opts = {}
      constructor_opts[:repo] = repo unless repo.nil?

      criteria = criteria_class.new(entity_key, constructor_opts)
      if opts.key?(:where)
        attr_key  = opts.delete(:where)
        op, value = opts.first
        return criteria.where(attr_key, op => value)
      end

      if opts.key?(:exists)
        attr_key  = opts.delete(:exists)
        op, value = opts.first
        return criteria.where(attr_key, op => value)
      end
      criteria
    end

    def ok(value = nil)
      self.class.ok(value)
    end

    def error(*args)
      self.class.error(*args)
    end

    def response?(value)
      self.class.response?(value)
    end

    def create_response(result)
      self.class.create_response(result)
    end

    def call(inputs, data = {})
      fail "Concrete handlers must implement their own call"
    end
  end
end
