module Appfuel
  # Dsl used my the feature module to add validators to it. These
  # validators can then injected into actions or commands.
  module Validators
    def validators
      @validators ||= {}
    end

    def validator?(name)
      validators.include?(name)
    end

    # Dsl to add a validator to the feature modules list of validators
    # which is stored as a hash on the feature module. When used without a
    # block then you must manually provide your own validator. When used with
    # a block, that block will be usesd with Dry::Validation, extending the
    # SpCore::AppValidator class. Which is equivalent to:
    #
    # Dry::Validation.Form(SpCore::AppValidator) do
    #  ...
    # end
    #
    # @param name Symbol  name to identity this validator
    # @param type Symbol  :form or :schem depending on the validator you want
    def validator(name, type = :form, &blk)
      return validator_with_block(name, type, &blk) if block_given?

      unless type.respond_to?(:call)
        fail "validator :#{name} must implement call"
      end

      validators[name] = type
    end

    private

    def validator_with_block(name, type, &blk)
      type = :form if type.nil?
      unless [:form, :schema].include?(type)
        fail "type must be :form or :schema #{type} given"
      end
      method = type.to_s.capitalize
      app_validator    = root_module.container[:app_validator]
      validators[name] = Dry::Validation.send(method, app_validator, &blk)
    end
  end
end
