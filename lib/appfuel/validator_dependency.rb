module Appfuel
  module ValidatorDependency
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

    def resolve_global_validator(name)
      # If the validator was a custom validator then it would have
      # responded to call. No validator should be a symbol
      mod = root_module
      fail "root module must be a Module" unless mod.is_a?(Module)

      if mod.respond_to?(:validators) && !mod.validators.key?(name)
        fail "global validator :#{name} not found in #{mod.class}"
      end

      mod.validators[name]
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
      mod  = feature_module
      fail "feature module must be a Module" unless mod.is_a?(Module)

      if !mod.respond_to?(:validators) || !mod.validators.key?(name)
        fail "feature validator :#{name} not found in #{mod.class}"
      end

      mod.validators[name]
    end
  end
end
