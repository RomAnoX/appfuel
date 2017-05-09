module Appfuel
  module Repository
    class Base
      include Appfuel::Application::AppContainer

      class << self
        attr_writer :mapper
        def inherited(klass)
          register_container_class(klass)
        end

        def mapper
          @mapper ||= create_mapper
        end

        def create_mapper(maps = nil)
          Mapper.new(maps)
        end
      end

      def mapper
        self.class.mapper
      end

      def to_storage(entity, exclude = [])
        mapper.to_storage(entity, exclude)
      end

      def to_entity(domain_name, storage)
        key  = qualify_container_key(domain_name, "domains")
        hash = mapper.to_entity_hash(domain_name, storage)
        app_container[key].new(hash)
      end

      def build(type:, name:, storage:, **inputs)
        builder = find_entity_builder(type: type, domain_name: name)
        builder.call(storage, inputs)
      end

      # features.membership.presenters.hash.user
      # global.presenters.user
      #
      # key => db_model
      # key => db_model
      def find_entity_builder(domain_name:, type:)
        key = qualify_container_key(domain_name, "domain_builders.#{type}")

        container = app_container
        unless container.key?(key)
          return ->(data, inputs = {}) {
            build_default_entity(domain_name: domain_name, storage: data)
          }
        end

        container[key]
      end

      def build_default_entity(domain_name:, storage:)
        storage = [storage] unless storage.is_a?(Array)

        storage_attrs = {}
        storage.each do |model|
          storage_attrs.merge!(mapper.model_attributes(model))
        end

        hash = mapper.to_entity_hash(domain_name, storage_attrs)
        key  = qualify_container_key(domain_name, "domains")
        app_container[key].new(hash)
      end
    end
  end
end
