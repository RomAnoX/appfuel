module Appfuel
  module Handler
    #
    #
    # 1) single block validator. A basic validator that is only used by
    #    that particular interactor
    #
    #
    #     validator('foo', fail_fast: true) do
    #
    #     end
    #
    # 2) single validator from the features validators located in the app
    #    container under the key "features.<feature-name>.validators.<validator-name>"
    #
    #    validator 'foo'
    #
    # 3) single validator from the global validators located in the app
    #   container under the key "global.validators.<validator-name>"
    #
    #   validator 'global.foo'
    #
    # 4) muliple validators, all are located in the feature namespace
    #   validators 'foo', 'bar', 'baz'
    #
    # 5) multiple validators, some in features other in global
    #   validators 'foo', 'global.bar', 'baz'
    #
    # 6) a pipe is a closure that lives before a given validator in order
    #    to manipulate the inputs to fit the next validator. it does not validate
    #
    #   validator_pipe do |inputs, data|
    #
    #   end
    #
    # 7) using a pipe when using muliple validators
    #
    #   validators 'foo', 'pipe.bar', 'base'
    #
    # 8) using global pipe in multiple validator declaration
    #   validators 'foo', 'global-pipe.bar', 'base'
    #
    # 9) validator_schema is used to use Dry::Validations with out our block
    #    processing
    #
    #    validation_schema 'foo', Dry::Validation.Schama do
    #
    #    end
    #
    #    validation_schema Dry::Validation.Schema do
    #
    #    end
    #
    #    validation_schema 'foo', fail_fast: true, Dry::Validation.Schema do
    #
    #    end
    #
    # validator
    #   name: to identify it in errors and as a key to register it with container
    #   fail_fast: when true runner will bail on first error
    #   pipe?: false
    #   code: validator schema to run
    #   call: run the validator schema
    #
    # validator-pipe
    #   name: to identify the pipe in errors and register it with container
    #   code: lambda to run
    #   call: run the lamda
    module ValidatorDsl

      def validator_keys
        @validator_keys ||= []
      end

      def validators(*args)
        @validators ||= []
        return @validators if args.empty?

        args.each do |arg|
          validator_keys << convert_to_container_key(arg)
        end
      end

      # When no name for a validator is given then the default name will
      # be the name of the concrete handler class
      #
      # @return [String]
      def default_validator_name
        self.to_s.split('::').last.underscore
      end

      # Converts a given block to a validator or load the validator from
      # either global or feature validators
      #
      # @param key [String] name of the validator
      # @param opts [Hash] options for creating a validator
      # @option fail_fast [Bool] allows that validator to fail immediately
      # @return [Nil]
      def validator(key = nil, opts = {}, &block)
        key  = default_validator_name if key.nil?
        unless block_given?
          validator_keys << convert_to_container_key(key)
          return
        end

        validators << Appfuel::Validation.build_validator(key, opts, &block)
        nil
      end

      # return [Bool]
      def validators?
        !(validators.empty? && validator_keys.empty?)
      end

      # Used when resolving inputs to determine if we should apply any
      # validation
      #
      # return [Bool]
      def skip_validation?
        @skip_validation == true
      end

      # Dsl method to allow a handler to tell the system not to validate
      # anything and use the raw inputs
      #
      # return [Bool]
      def skip_validation!
        @skip_validation = true
      end

      def load_validators
        list = validators
        return list unless list.empty?
        validator_keys.each do |key|
          @validators << load_validator(key, no_context: true)
        end
        validators
      end

      # Validate all inputs using the list of validators that were assigned
      # using the dsl methods.
      #
      # @param inputs [Hash]
      # @return Appfuel::Response
      def resolve_inputs(inputs = {})
        return ok(inputs) if skip_validation?
        return ok({}) unless validators?

        inputs.deep_symbolize_keys!
        response = nil
        has_failed = false
        load_validators.each do |validator|
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

          return error(result.errors(full: true)) if validator.fail_fast?
          has_failed = true
          response = handle_error_inputs(result, response)
        end

        fail "multi validators can not be only Procs" if response.nil?

        response
      end

      def load_validator(key, opts = {})
        unless opts[:no_context] == true
          key = convert_to_container_key(key)
        end

        container = app_container
        feature_name = extract_feature_name(key)
        unless feature_initialized?(feature_name)
          initialize_feature(feature_name)
        end

        unless container.key?(key)
          fail "Could not locate validator with (#{key})"
        end
        container[key]
      end

      private

      # Decodes the given key into a dependency injection namespace that is
      # used to find a validator or pipe in the app container. It decodes
      # to a global or feature namespaces.
      #
      # @param key [String]
      # #return [String]
      def convert_to_container_key(key)
        # normalize the key to the current feature when no feature
        # is specified
        unless key.include?('.')
          key = "#{container_feature_name}.#{key}"
        end
        parts = key.to_s.split('.')
        last  = parts.last
        first = parts.first
        prefix = container_feature_key
        if first != 'global' && first != container_feature_name
          prefix = "#{container_features_root_name}.#{first}"
        end

        case first
          when 'global'      then "global.validators.#{last}"
          when 'global-pipe' then "global.validator-pipes.#{last}"
          when 'pipe'        then "#{prefix}.validator-pipes.#{last}"
          else
            "#{prefix}.validators.#{last}"
        end
      end


      # Creates a response the first time otherwise it merges the results
      # from the last validator into the response
      #
      # @param results [Hash] successful valid inputs
      # @param response [Appfuel::Response]
      def handle_successful_inputs(result, response)
        if response.nil?
          ok(result.output)
        else
          ok(response.ok.merge(result.output))
        end
      end

      # Creates a response the first time otherwise it merges the error
      # results from the last validator into the response
      #
      # @param results [Hash] successful valid inputs
      # @param response [Appfuel::Response]
      def handle_error_inputs(result, response)
        if response.nil?
          error(result.errors(full: true))
        else
          error(result.errors(full: true).merge(response.error_messages))
        end
      end

      # Delegates call to the validator pipe
      #
      # @param pipe [Appfuel::Validation::ValidatorPipe]
      # @param inputs [Hash]
      # @return [Hash]
      def handle_validator_pipe(pipe, inputs)
        result = pipe.call(inputs, Dry::Container.new)
        return false unless result
        unless result.is_a?(Hash)
          fail "multi validator proc must return a Hash"
        end
        result
      end
    end
  end
end
