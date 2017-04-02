module Appfuel
  module Domain
    class EntityNotFound < Entity
      attribute 'entity_name', 'string'

      def initialize(inputs = {})
        entity_name = inputs[:entity_name]
        if entity_name.nil? || entity_name == Types::Undefined
          fail ":entity_name is a required attribute"
        end
        @entity = Types[entity_name].new({})
        super
      end

      def method_missing(method, *args, &block)
        if @entity.respond_to?(method)
          return Types::Undefined
        end

        super
      end

      def collection?
        false
      end

      def global?
        @entity.global?
      end

      def attr_typed!(name, value)
        @entity.attr_typed!(name, value)
      end

      def data_typed!(type_name, value)
        @entity.data_typed!(type_name, value)
      end

      def data_type(type_name)
        @entity.data_type(type_name)
      end

      def validate_type!(value, type_str, **options)
        @entity.validate_type!(value, type_str, **options)
      end

      def domain_name
        @entity.domain_name
      end

      def domain_basename
        @entity.domain_basename
      end

      def has?(key)
        false
      end

      def to_hash
        @entity.to_h
      end
    end
  end
end
