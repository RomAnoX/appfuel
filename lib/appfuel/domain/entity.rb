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
    class Entity
      include Appfuel::Application::AppContainer
      extend Dsl

      def initialize(inputs = {})
        setup_attributes(inputs)
        enable_undefined
        @is_global = domain_name.count('.') == 0

      rescue Dry::Types::ConstraintError => e
        msg = "#{self.class.name} could not initialize: #{e.message}"
        error = RuntimeError.new(msg)
        error.set_backtrace(e.backtrace)
        raise error
      end

      def global?
        @is_global
      end

      def collection?
        false
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
        show_undefined
        @undefined_as_nil = false
        each_entity do |entity|
          entity.enable_undefined
        end
      end

      def undefined_as_nil
        @undefined_as_nil = true
        each_entity do |entity|
          entity.undefined_as_nil
        end
      end

      def undefined_as_nil?
        @undefined_as_nil
      end

      def attr_typed!(name, value)
        self.class.schema[name.to_sym][value]
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

      def domain_basename
        self.class.domain_basename
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
              list << (item.is_a?(Entity) ? item.to_hash : item)
            end
            value = list
          when value.is_a?(Hash)
            dict = {}
            value.each do |value_key, item|
              dict[value_key] = item.is_a?(Entity) ? item.to_hash : item
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
          if type.respond_to?(:<) && type < Dsl && has?(key)
            yield send(key)
          end
        end
      end

      def each_attr
        each_attr_schema do |key, type|
          yield key, send(key)
        end
      end

      def value_object?
        self.class.value_object?
      end

      def setup_attributes(inputs = {})
        inputs = {} if inputs.nil?
        inputs = inputs.to_h if inputs == self

        unless inputs.is_a?(Hash)
          fail "Can not create #{self} entity inputs must be a Hash"
        end

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
        input = handle_default_value(input, type)
        if respond_to?("#{key}=")
          return handle_defined_setter(key, input)
        end

        input = type_check_value(type, input)
        instance_variable_set("@#{key}", input)
      rescue => e
        msg   = "#{domain_name} could not assign :#{key} #{e.message}"
        error = RuntimeError.new(msg)
        error.set_backtrace(e.backtrace)
        raise error
      end

      def handle_defined_setter(key, input)
        return if undefined?(input)
        send("#{key}=", input)
      end

      def handle_default_value(input, type)
        return input unless type.default?
        if undefined?(input) || input.nil?
          return type[nil]
        end
        input
      end

      def type_check_value(type, input)
        if !undefined?(input) && !input.nil?
          input = type[input]
        end
        input
      end

      def setter_defined?(key)
        respond_to?("#{key}=")
      end

      def define_getter(key)
        return if respond_to?(key)
        define_singleton_method(key) do
          value = instance_variable_get("@#{key}")
          value = nil if value == Types::Undefined && undefined_as_nil?
          value
        end
      end

      def define_setter(key, type)
        setter = "#{key}="
        return if respond_to?(setter)

        define_singleton_method(setter) do |input|
          value = is_entity?(input, type) ? input : type[input]
          instance_variable_set("@#{key}", value)
        end
      end

      def freeze_instance_var(key)
        instance_variable_get("@#{key}").freeze
      end


      def undefined?(value)
        value == Types::Undefined
      end

      def is_entity?(value, type)
        value.respond_to?(:domain_name) && value.domain_name == type.domain_name
      end
    end
  end
end
