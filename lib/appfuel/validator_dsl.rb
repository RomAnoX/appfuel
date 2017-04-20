module Appfuel
  # 1) single block validator. A basic validator that is only used by
  #    that particular interactor
  #
  #     validator do
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

      args.each do |arg|
        name = arg
        opts = {}
        if arg.is_a?(Hash)
          name = arg.delete(:validator)
          opts = arg
        end

        validate_fail_fast(opts)
        @validators << {
          validator: load_validator(name, opts),
          fail_fast: opts[:fail_fast]
        }
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

    def validator(type = nil, opts = {}, &blk)
      validate_fail_fast(opts)
      return validator_with_block(type, opts, &blk) if block_given?

      if type.respond_to?(:call)
        validators << {validator: type, fail_fast: opts[:fail_fast]}
        return
      end

      unless type.is_a?(Symbol)
        fail 'first arg must be a symbol or respond to :call if no block is given'
      end


      validators << {validator: load_validator(type, opts), fail_fast: opts[:fail_fast]}
    end

    def load_validator(key, opts = {})
      fail "validator must have a key" if key.nil?
      if [:schema, :form].include?(key)
        fail ':form and :schema are reserved validator keys'
      end

      if opts[:global] == true
        resolve_global_validator(key)
      else
        resolve_feature_validator(key)
      end
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

    def validate_fail_fast(opts = {})
      opts[:fail_fast] = opts[:fail_fast] == true ? true : false
    end

    def validator_with_block(type, opts, &blk)
      # happens with an anonomous validator that needs to fail fast
      if type.is_a?(Hash)
        opts = type
        type = nil
      end

      type = :form if type.nil?
      unless [:form, :schema].include?(type)
        fail "type must be :form or :schema #{type} given"
      end
      method = type.to_s.capitalize

      app_validator = root_module.container[:app_validator]
      schema = Dry::Validation.send(method, app_validator, &blk)
      validators << {validator: schema, fail_fast: opts[:fail_fast]}
    end

    def resolve_feature_validator(name)
      ap 'i am in resolve feature validators'
    end

    def resolve_global_validator(name)
      ap 'i am in resolve global validators'
    end

  end
end
