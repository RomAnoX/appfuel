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
    #   validator Dry::Validation.Form {
    #     required(:name).filled
    #   }
    #
    #   define :bam do
    #     defaults bat: 'hit',
    #              rat: 'cheese'
    #
    #     validator Dry::Validation.Form {
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
        @file_type = :yaml
        @validator = nil
        @children  = {}
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

      def file_type(value = nil)
        return @file_type if value.nil?
        value = value.to_s.downcase.to_sym
        unless [:json, :yaml].include?(value)
          fail "only json and yaml are supported"
        end
        @file_type = value
      end

      # Dsl used when you expected to manually pass in the configuration data
      # and ignore the configuration in the file
      #
      # @return nil
      def delete_file
        @file = []
      end

      #
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

      # Dsl to assign validator. When no params are given then it returns
      # the assigned validator. We use the validation library dry-validation
      # http://dry-rb.org/gems/dry-validation/. We will consider any object
      # that implements `call` method a validator.
      #
      # @params validator Dry::Validation::Schema
      # @return validator
      def validator(handler = nil)
        return @validator if handler.nil?
        unless handler.respond_to?(:call)
          fail ArgumentError, 'validator must implement call'
        end
        @validator = handler
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

      # Allow you to access child definitions as if it were a hash.
      # If you add a space separated list of names this will traverse
      # the child hierarchy and return the last name in the list
      #
      # @param name String name or names to search
      # @return Definition | nil
      def [](name)
        find @children, name.to_s.split(" ")
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

      # Allows you to search child definitions using an array of names
      # instead of a space separated string
      #
      # @param names Array of strings
      # @return Definition | nil
      def search(*names)
        return nil if names.empty?
        find children, names
      end

      # This converts a definition into a hash of configuation values. It does
      # this using the following steps
      #
      # 1. load config data from a yaml file if a file is defined
      # 2. populate all children
      # 3. merge defaults into config data that has been given or resolved
      #    from the config file
      # 4. merge override data into the results from step 3
      # 5. run validation and assign clean data to config with the key
      #
      # @throws RuntimeError when validation fails
      # @param data Hash holds overrides and config source data
      # @return Hash
      def populate(data = {})
        overrides = data[:overrides] || {}
        config    = data[:config] || {key => {}}

        if overrides.key?(:config_file) && !overrides[:config_file].nil?
          file overrides[:config_file]
        end

        config = load_file(self) if file?
        config[key] ||= {}

        config[key] = defaults.deep_merge(config[key])
        config[key] = config[key].deep_merge(overrides[key] || {})

        populate_children(children, config[key]) unless children.empty?

        config[key] = handle_validation(config[key])
        config
      end

      protected
      attr_accessor :children

      # Recursively locate a child definition in the hierarchy
      #
      # @param child_list Hash
      # @param terms Array of definition keys
      def find(child_list, terms)
        while term = terms.shift
          child_list.each do |(definition_key, definition)|
            next unless definition_key == term
            result = if terms.empty?
                       definition
                     else
                       find(definition.children, terms)
                     end
            return result
          end
        end
      end

      def populate_children(child_hash, data)
        child_hash.each do |(def_key, definition)|
          data[def_key] ||= {}
          data[def_key] = load_file(definition) if definition.file?

          data[def_key] = definition.defaults.deep_merge(data[def_key])

          unless definition.children.empty?
            populate_children(definition.children, data[def_key])
          end

          data[def_key] = definition.handle_validation(data[def_key])
       end
      end

      def handle_validation(data)
        return data unless validator?

        result = validator.call(data)
        if result.failure?
          msg = validation_error_message(result.errors(full: true))
          fail msg
        end
        result.to_h
      end

      def validation_error_message(errors)
        msg = ''
        errors.each do |(error_key, values)|
          if values.is_a?(Hash)
            values = values.values.uniqu
          end
          msg << "[#{key}] #{error_key}: #{values.join("\n")}\n"
        end
        msg
      end
    end
  end
end
