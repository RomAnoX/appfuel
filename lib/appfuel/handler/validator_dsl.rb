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
    #    validator Dry::Validation.Schama do
    #
    #    end
    #
    #    validator 'foo', Dry::Validation.Schema do
    #
    #    end
    #
    #    validator 'foo', Dry::Validation.Schema, fail_fast: true do
    #
    #    end
    #
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
      def validators(*args)
        @validators ||= []
        return @validators if args.empty?

        container = Appfuel.app_container
        args.each do |arg|
          container_key = convert_to_container_key(arg)
          container = Appfuel.app_container
          @validators << container[container_key]
        end
      end

      def convert_to_container_key(key)
        parts = key.to_s.split('.')
        last  = part.last
        first = parts.first
        case first
          when 'global'      then "global.validators.#{last}"
          when 'global-pipe' then "global.validator-pipes.#{last}"
          when 'pipe'        then "#{feature_key}.validator-pipes.#{last}"
          else
            "#{feature_key}.validators.#{first}"
        end
      end

      def dynamic_inputs(callable, opts = {})
        callable = load_validator(callable, opts) if callable.is_a?(Symbol)
        if !callable.respond_to?(:lambda?) || !callable.lambda?
          fail "dynamic validation inputs must be a lambda"
        end

        if callable.arity != 2
          fail "dynamic input lambda must have 2 params (inputs, data)"
        end

        validators << {validator: callable, fail_fast: false}
      end


      def default_validator_name
        self.to_s.split('::').last.underscore
      end

      def validator(key = nil, opts = {}, &block)
        key = default_validator_name if key.nil?
        return handle_validator_block(key, opts, &block) if block_given?


        validators << load_validator(type, opts)
      end

      def load_validator(key, opts = {})
        fail "validator must have a key" if key.nil?

        container_key = convert_to_container_key(key)
        container = Appfuel.app_container
        unless container.key?(container_key)
          fail "Could not locate validator with (#{container_key})"
        end
        container[container_key]
      end

      def validators?
        !validators.empty?
      end

      def skip_validation?
        @skip_validation == true
      end

      def skip_validation!
        @skip_validation = true
      end

      private

      def handle_validator_block(key, opts = {}, &block)
        fail_fast   = opts[:fail_fast] == true ? true : false
        schema_type = (opts.fetch(:type) { 'form' }).to_s.downcase
        unless ['form', 'schema'].include?(schema_type)
          fail "validator type must 'form' or 'schema' (#{schema_type}) given"
        end

        method = schema_type.capitalize
        schema = Dry::Validation.send(method, &block)
        validators << Validation::Validator.new(key, schema, fail_fast: fail_fast)
      end

      def resolve_feature_validator(name)
        ap 'i am in resolve feature validators'
      end

      def resolve_global_validator(name)
        ap 'i am in resolve global validators'
      end
    end
  end
end
