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
    module Base
      def initialize(inputs = {})
        setup_attributes(inputs)
        hide_undefined
        undefined_as_nil
      rescue Dry::Types::ConstraintError => e
        msg = "#{self.class.name} could not initialize: #{e.message}"
        error = RuntimeError.new(msg)
        error.set_backtrace(e.backtrace)
        raise error
      end

      def hide_undefined?
        @hide_undefined
      end

      def hide_undefined
        @hide_undefined = true
      end

      def show_undefined
        @hide_undefined = false
      end

      def enable_undefined
        @undefined_as_nil = false
        each_entity do |entity|
          entity.enable_undefined
        end
      end

      def undefined_as_nil
        each_entity do |entity|
          entity.undefined_as_nil
        end
      end

      def attr_typed!(name, value)
        self.class.schema[name][value]
      end

      def data_typed!(type_name, value)
        data_type(type_name)[value]
      end

      def data_type(type_name)
        self.class.type(type_name)
      end

      def validate_type!(value, type_str, **options)
        type = self.class.build_type(type_str, **options)
        type[value]
      end

      def domain_name
        self.class.domain_name
      end

      def basename
        self.class.basename
      end

      def to_hash
        data = {}
        self.class.schema.each do |key, type|
          fail "no getter defined for #{key}" unless respond_to?(key)
          value = send(key)
          case
          when value.is_a?(Array)
            list = []
            value.each do |item|
              list << (item.is_a?(Appfuel::Entity) ? item.to_hash : item)
            end
            value = list
          when value.is_a?(Hash)
            dict = {}
            value.each do |value_key, item|
              dict[value_key] = item.is_a?(Appfuel::Entity) ? item.to_hash : item
            end
            value = dict
          when value.respond_to?(:to_hash)
            value = value.to_hash
          when value == Types::Undefined
            if type.respond_to?(:domain_name)
              value = type.empty_hash(undefined_as_nil? ? true : false)
            end
            next if hide_undefined?

          end
          data[key] = value
        end
        data.deep_symbolize_keys
      end

      def to_h
        to_hash
      end

      def has?(key)
        value = send(key)
        !value.nil? && value != Types::Undefined
      end

      private

      def each_attr_schema
        self.class.schema.each do |key, type|
          yield key, type
        end
      end

      def each_entity
        each_attr_schema do |key, type|
          if type.respond_to?(:<) && type < Appfuel::Attributes && has?(key)
            yield send(key)
          end
        end
      end

      def value_object?
        self.class.value_object?
      end

      def setup_attributes(inputs = {})
        inputs = {} if inputs.nil?
        fail "entity inputs must be a Hash" unless inputs.is_a?(Hash)

        inputs.deep_symbolize_keys!
        self.class.schema.each do |key, type|

          value = Types::Undefined
          value = inputs[key] if inputs.key?(key)
          if value_object?
            setup_value_object(key, type, value)
            next
          end
          setup_entity(key, type, value)
        end
      end

      def setup_value_object(key, type, input)
        define_getter(key)
        initialize_value(key, type, input)
        freeze_instance_var(key)
      end

      def setup_entity(key, type, input)
        define_getter(key)
        initialize_value(key, type, input)
        define_setter(key, type)
      end

      def initialize_value(key, type, input)
        if input == Types::Undefined && type.default?
          input = type[nil]
        end

        # manual overrides have to manually type check themselves
        setter = "#{key}="
        return send(setter, input) if respond_to?(setter)

        if input != Types::Undefined && input != nil
          input = type[input]
        end

        instance_variable_set("@#{key}", input)
      rescue => e
        msg   = "#{domain_name} could not assign :#{key} #{e.message}"
        error = RuntimeError.new(msg)
        error.set_backtrace(e.backtrace)
        raise error
      end

      def define_getter(key)
        return if respond_to?(key)
        define_singleton_method(key) do
          instance_variable_get("@#{key}")
        end
      end

      def define_setter(key, type)
        setter = "#{key}="
        return if respond_to?(setter)

        define_singleton_method(setter) do |input|
          instance_variable_set("@#{key}", type[input])
        end
      end

      def freeze_instance_var(key)
        instance_variable_get("@#{key}").freeze
      end
    end
  end
end
