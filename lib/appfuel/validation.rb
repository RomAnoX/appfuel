require_relative 'validation/validator'
require_relative 'validation/validator_pipe'

module Appfuel
  module Validation
    class << self
      def define(key, name, opts = {}, &block)
        validator_key = "#{key}.validators.#{name}"
        container = Appfuel.app_container
        validator = build_validator(name, opts, &block)
        container.register(validator_key, validator)
      end

      def build_validator(name, opts = {}, &block)
        fail_fast   = opts[:fail_fast] == true ? true : false
        schema_type = (opts.fetch(:type) { 'form' }).to_s.downcase
        unless ['form', 'schema'].include?(schema_type)
          fail "validator type must 'form' or 'schema' (#{schema_type}) given"
        end

        fail "block is required to build a validator" unless block_given?

        method = schema_type.capitalize
        schema = Dry::Validation.send(method, &block)

        Validator.new(name, schema, fail_fast: fail_fast)
      end
    end
  end
end

