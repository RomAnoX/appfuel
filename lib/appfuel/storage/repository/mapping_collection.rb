module Appfuel
  module Repository
    class MappingCollection
      attr_reader :map

      def initialize(map = {})
        @map = map
        fail "map must be a hash" unless map.is_a?(Hash)
      end

      # map {
      #  domain_name => {
      #   type => map
      #  }
      # }
      def load(storage_map)
        domain_name  = storage_map.domain_name
        storage_type = storage_map.storage_type
        map[domain_name] = {} unless  map.key?(domain_name)
        map[domain_name][storage_type] = storage_map
      end
    end
  end
end
