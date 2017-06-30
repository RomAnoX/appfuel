module Appfuel
  module Repository
    class MappingCollection
      attr_reader :collection

      def initialize(collection = {})
        @collection = collection
        fail "collection must be a hash" unless collection.is_a?(Hash)
      end

      # map {
      #  domain_name => {
      #   type => map
      #  }
      # }
      def load(storage_map)
        domain_name  = storage_map.domain_name
        storage_type = storage_map.storage_type
        collection[domain_name] = {} unless  collection.key?(domain_name)
        collection[domain_name][storage_type] = storage_map
      end

      def entity?(domain_name)
        collection.key?(domain_name)
      end

      def storage_attr(type, domain_name, domain_attr)
        map = storage_map(type, domain_name)
        map.storage_attr(domain_attr)
      end

      def storage_key(type, domain_name)
        map = storage_map(type, domain_name)
        map.storage_key
      end

      def container_name(type, domain_name)
        map = storage_map(type, domain_name)
        map.container_name
      end

      def each_attr(type, domain_name, &block)
        map = storage_map(type, domain_name)
        map.each(&block)
      end

      def storage_map(type, domain_name)
        unless entity?(domain_name)
          fail "#{domain_name} is not registered in map"
        end

        unless map[domain_name].key?(type)
          fail "#{domain_name} storage #{type} is not registered in map"
        end

        map[domain_name][type]
      end
    end
  end
end
