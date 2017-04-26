require_relative 'validation/validator'
require_relative 'validation/validator_pipe'

module Appfuel
  module Validation
    class << self
      # Dsl used create and register validators in the app container. The key
      # needs to be the fully qualified feature or global.
      #
      #
      # @example define 'global.foo' do
      #            required(:test).filled(:str?)
      #          end
      #
      #          this will add a validator in 'global.validators.foo'
      #
      # @example define 'auth.foo' do
      #            required(:test).filled(:str?)
      #          end
      #
      #          this will add a validator in 'features.auth.validators.foo'
      #
      # @param key [String] qualified key to global or feature namespace
      # @param opts [Hash] options
      # @return Validator
      def define(name, opts = {}, &block)
        key, basename = build_validator_key(name)
        container     = Appfuel.app_container
        validator     = build_validator(basename, opts, &block)
        container.register(key, validator)
      end

      # Turns the block of code given into a Dry::Validation schema or formi
      # which is then used to create our validator.
      #
      # @param name [String] key used to register this validator in the container
      # @param opts [Hash] options to configure validator
      # @option type [String] form or schema for dry validation
      # @option fail_fast [Bool] tells the system to fail right away
      # @return Validator
      def build_validator(name, opts = {}, &block)
        fail_fast   = opts[:fail_fast] == true ? true : false
        schema_type = (opts.fetch(:type) { 'form' }).to_s.downcase

        schema = create_dry_validator(schema_type, &block)
        Validator.new(name, schema, fail_fast: fail_fast)
      end

      # Factory method create Dry::Validation::Schema or
      # Dry::Validation::Schema::Form objects
      #
      # @param type [String] form or schema
      def create_dry_validator(type, &block)
        unless ['form', 'schema'].include?(type)
          fail "validator type must 'form' or 'schema' (#{type}) given"
        end

        fail "block is required to build a validator" unless block_given?

        method = type.capitalize
        Dry::Validation.send(method, &block)
      end
      private

      # Construct a full qualified namespace key to register a validator with.
      # The basename of that key is used when creating the valdiator so it
      # is returned with the key.
      #
      # @param name [String] partial namespace string of container key
      # @return [Array] the fully qualified key and the basename
      def build_validator_key(name)
        key, *parts = name.to_s.split('.')
        key = "features.#{key}" unless key == 'global'
        ["#{key}.validators.#{parts.join('.')}", parts.last]
      end

    end
  end
end

