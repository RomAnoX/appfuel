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

      def to_storage(entity)
        mapper.to_storage(entity)
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
      def find_entity_builder(domain_name:, type:)
        key = qualify_container_key(domain_name, "domain_builders.#{type}")

        container = app_container
        unless container.key?(key)
          return ->(data, inputs = {}) {
            hash = mapper.to_entity_hash(domain_name, data)

            domain_key = qualify_container_key(domain_name, "domains")
            app_container[domain_key].new(hash)
          }
        end

        container[key]
      end
    end
  end
end
