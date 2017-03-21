module Appfuel
  # Mixin used to add attributes to an object. Attributes are given an name
  # and have a type declaration which is used to ensure it is correct. Types
  # are handled by Dry::Types which are mixed into the Types module. When an
  # object is instaniated dymamic getters and setters are created depending
  # on if the a value_object flag has been toggled
  #
  # @example
  #   attribute :foo, 'strict.string', default: 'bar', min_size: 3
  #
  module Domain
    module Dsl
      def self.included(base)
        base.class_eval do
          extend ClassMethods
        end
      end

      # Class macro dsl used to implement attributes
      module ClassMethods
        include Dry::Types::Builder

        attr_accessor :equalizer
        attr_reader :schema, :defaults
        protected :equalizer=

        def self.extended(base)
          base.instance_variable_set(:@schema, {})
          base.instance_variable_set(:@value_object, false)
        end

        def inherited(klass)
          super
          klass.instance_variable_set(:@schema, {})
          klass.equalizer = Dry::Equalizer.new(*schema.keys)
          klass.send(:include, klass.equalizer)

          Types.register_domain(klass)
        end

        def default?
          false
        end

        def valid?(value)
          self === value
        end

        def value_object?
          @value_object
        end

        def enable_value_object
          @value_object = true
        end

        def disable_value_object
          @value_object = false
        end

        def type(str)
          Types[str]
        end

        def strict_enum(*args)
          type('strict.string').enum(*args)
        end

        def enum(*args)
          type('coercible.string').enum(*args)
        end

        def attribute_names
          schema.keys
        end

        def attribute(name, type_str, **options)
          unless type_str.is_a?(String)
            return handle_manual_type(name, type_str, options)
          end

          name = name.to_sym
          type = build_type(type_str, options)
          schema[name] = type unless attribute_exists?(name, type)
          nil
        end

        def build_type(type_str, **options)
          base = type_str.split('.').last
          type = Types[type_str]
          type = apply_defaults(type, options)
          type = apply_optional(type, options)

          nil_is_allowed = allow_nil?(options)

          type = case base
                 when 'hash'  then handle_hash(type, options)
                 when 'array' then handle_array(type, options)
                 else
                   type
                 end

          type = apply_constraints(type, options)

          # You have to apply all the contraints before summing nil
          type = sum_nil(type) if nil_is_allowed

          type
        end

        def attribute_exists?(name, type)
          schema[name.to_sym] === type
        end

        def attribute_conflict?(name, type)
          name = name.to_sym
          schema.key?(name) && schema[name] != type
        end

        def create(inputs = {})
          self.new(inputs)
        end

        alias_method :call, :create
        alias_method :[], :create

        def try(input)
          Dry::Types::Result::Success.new(self[input])
        rescue => e
          failure = Dry::Types::Result::Failure.new(input, e.message)
          block_given? ? yield(failure) : failure
        end

        def domain_name
          @domain_name ||= build_domain_name
        end

        def basename
          domain_name.split('.').last
        end

        def empty_hash(undefined_as_nil = false)
          data  = {}
          value = undefined_as_nil == true ? nil : Types::Undefined
          schema.keys.each do |key|
            data[key] = value
          end
          data
        end

        def to_s
          domain_name
        end

        private

        def parse_class_name
          return ["anonmous_#{generate_code(6)}"] if name.nil?
          name.underscore.split('/')
        end

        def build_domain_name
          parse_class_name.delete_if do |x|
            ['sp_service', 'appfuel', 'domains'].include?(x)
          end.join('.')
        end

        def generate_code(nbr)
          charset = Array('A' .. 'Z') + Array('a' .. 'z')
          Array.new(nbr) { charset.sample }.join
        end

        def handle_manual_type(name, type, options)
          name = name.to_sym
          type = apply_defaults(type, options)
          if attribute_conflict?(name, type)
            fail RuntimeError, "Attribute :#{name} has already been defined " +
              "as another type"
          end

          schema[name] = type unless attribute_exists?(name, type)
        end

        def handle_hash(type, options)
          return type unless options.key?(:hash)
          constructor = options.fetch(:constructor) { :schema }
          options.delete(:constructor)
          valid = [
            :schema,
            :weak,
            :permissive,
            :strict,
            :strict_with_defaults,
            :symbolized
          ]

          unless valid.include?(constructor)
            fail "the :constructor of the hash must be one of the " +
              "following (#{valid.join(' ')})"
          end

          unless options[:hash].is_a?(Hash)
            fail ":hash params must be a hash"
          end

          if options[:hash].empty?
            fail ":hash params that are empty don't make sense you probably " +
              "want to exclude the params and use the constructor alone"
          end

          hash = options.delete(:hash)
          params = {}
          hash.each do |key, value|
            params[key] = value.is_a?(String) ? Types[value] : value
          end
          type.send(constructor, params)
        end

        def handle_array(type, options)
          if options.key?(:member)
            member = options.delete(:member)
            member = member.is_a?(String) ? Types[member] : member
            type = type.member(member)
          end
          type
        end

        def apply_defaults(type, options)
          return type unless options.key?(:default)

          type.default(options.delete(:default))
        end

        def apply_optional(type, options)
          return type unless options.key?(:optional)

          options.delete(:optional)
          type.optional
        end

        def apply_constraints(type, options)
          return type if options.empty?
          type.constrained(options)
        end

        def allow_nil?(options)
          result = false
          if options.key?(:allow_nil)
            options.delete(:allow_nil)
            result = true
          end
          result
        end

        def sum_nil(type)
          type | Types['strict.nil']
        end
      end
    end
  end
end
