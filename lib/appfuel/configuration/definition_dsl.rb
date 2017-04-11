module Appfuel
  module Configuration
    # A configuration definition holds the methods that are exposed in
    # Config dsl. This definition allows you to define a given configuration
    # as it would exist in a hash. The dsl collects information like where
    # the file that holds the config data is stored, validation for that
    # data and default values. Just like hashes can have nested hashes
    # you can have nested definitions using the "define" method
    #
    # NOTE: currently we only support yaml config files
    #
    # @example of dsl usage
    #
    # Appfuel::Configuration.define :foo do
    #   file /etc/startplus/offers.yml
    #   defaults bar: 'bif',
    #            baz: 'biz'
    #
    #   env FOO_BAR: :bar,
    #       FOO_BAZ: :baz
    #
    #   unsafe :some_key, :other_key
    #
    #   validator  {
    #     required(:name).filled
    #   }
    #
    #   define :bam do
    #     defaults bat: 'hit',
    #              rat: 'cheese'
    #
    #     validator {
    #       required(:cheese_type).filled
    #     }
    #   end
    # end
    #
    # Results in something like this
    #
    # hash = {
    #   foo: {
    #     bar: 'bif',
    #     baz: 'baz',
    #     name: <user supplied>,
    #     bam: {
    #       bat: 'hit',
    #       rat: 'cheese',
    #       cheese_type: <user supplied>
    #     }
    #   }
    # }
    #
    class DefinitionDsl
      include FileLoader
      include Search
      include Populate
      attr_reader :key

      # A definition must be created with a key that will be used in the
      # resulting configuration hash that is built
      #
      # @param key Symbol|String key used config hash
      # @return Definition
      def initialize(key)
        @key       = key
        @defaults  = {}
        @file      = []
        @validator = nil
        @children  = {}
        @env       = {}
      end

      # Dsl command used to set the file path. When used without params
      # it returns the file path set.
      #
      # @param path String
      # @return String | nil
      def file(path = nil)
        return @file  if path.nil?
        path = [path] if path.is_a?(String)

        unless path.is_a?(Array)
          fail "file path must be a String or Array of Strings"
        end
        @file = path
      end

      def file?
        !@file.empty?
      end

      # Dsl used when you expected to manually pass in the configuration data
      # and ignore the configuration in the file
      #
      # @return nil
      def delete_file
        @file = []
      end

      # Dsl command used to set default values. When used without params
      # it returns the full default hash
      #
      # @param settings Hash
      # @return Hash
      def defaults(settings = nil)
        return @defaults if settings.nil?
        unless settings.is_a?(Hash)
          fail ArgumentError, 'defaults must be a hash'
        end

        @defaults = settings
      end

      # Dsl command used to define what env variables will me mapped to config
      # keys
      #
      # @param settings Hash
      # @option <key>=><value> The key is the env variable and the value is
      #                        the config key it maps to
      # @return Hash
      def env(settings = nil)
        return @env if settings.nil?
        unless settings.is_a?(Hash)
          fail ArgumentError, 'config env settings must be a hash'
        end

        @env = settings
      end

      # Dsl to assign validator. When no params are given then it returns
      # the assigned validator. We use the validation library dry-validation
      # http://dry-rb.org/gems/dry-validation/. We will consider any object
      # that implements `call` method a validator.
      #
      # @params validator Dry::Validation::Schema
      # @return validator
      def validator(&block)
        return @validator unless block_given?

        @validator = Dry::Validation.Schema(&block)
      end

      def validator?
        !@validator.nil?
      end

      # Dsl to add a configuration definition as a child of another
      # definition
      #
      # @param key Symbol
      # @return Details
      def define(key, &block)
        definition = self.class.new(key)
        definition.instance_eval(&block)
        self << definition
      end

      def delete(name)
        @children.delete(name)
      end

      # Append a definition to this definition's children
      #
      # @param definitions Array | Definition
      def <<(definitions)
        list = definitions.is_a?(Array) ? definitions : [definitions]
        list.each {|item| children[item.key] = item}
      end

      protected
      attr_accessor :children

    end
  end
end
