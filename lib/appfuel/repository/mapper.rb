module Appfuel
  module Repository
    # The mapping registry holds all entity to db mappings. Mappings are
    # contained within a DbEntityMapEntry object and are arranged by
    # entity name. Each entity will hold a hash where the keys are the
    # attribute names and the value is the entry
    class Mapper
      attr_reader :container_root_name

      def initialize(app_name, map = nil)
        @container_root_name = app_name
        if !map.nil? && !map.is_a?(Hash)
          fail "repository mappings must be a hash"
        end
        @map = map
      end

      # The map represents domain mappings to one or more storage systems.
      # Currently one map represents all storage. So if you have a file, and
      # database storage for a given domain the storage attributes are the same
      # for each interface. This will load the repository mappings from the
      # application container if no map as been manually set.
      #
      # @example a map has the following structure
      #   {
      #     domain_name: {
      #       domain_attr1: <MappingEntry>,
      #       domain_attr1: <MappingEntry>
      #     }
      #     ...
      #   }
      # @return [Hash]
      def map
        @map ||= mappings_from_container
      end

      # Determine if an entity has been added
      #
      # @param entity [String]
      # @return [Boolean]
      def entity?(entity_name)
        map.key?(entity_name)
      end

      # Determine if an attribute is mapped for a given entity
      #
      # @param entity [String] name of the entity
      # @param attr [String] name of the attribute
      # @return [Boolean]
      def entity_attr?(entity_name, entity_attr)
        return false unless entity?(entity_name)

        map[entity_name].key?(entity_attr)
      end

      # Returns a mapping entry for a given entity
      #
      # @raise [RuntimeError] when entity not found
      # @raise [RuntimeError] when attr not found
      #
      # @param entity [String] name of the entity
      # @param attr [String] name of the attribute
      # @return [Boolean]
      def find(domain_name, domain_attr)
        validate_domain(domain_name)

        unless map[domain_name].key?(domain_attr)
          fail "Domain (#{domain_name}) attr (#{domain_attr}) not registered"
        end
        map[domain_name][domain_attr]
      end

      # Iterates over all entries for a given entity
      #
      # @yield [attr, entry] expose the entity attr name and entry
      #
      # @param entity [String] name of the entity
      # @return [void]
      def each_domain_attr(domain_name)
        validate_domain(domain_name)

        map[domain_name].each do |attr, entry|
          yield attr, entry
        end
      end

      # Determine if an column is mapped for a given entity
      #
      # @param entity [String] name of the entity
      # @param attr [String] name of the attribute
      # @return [Boolean]
      def storage_attr_mapped?(domain_name, storage_attr)
        each_domain_attr(entity) do |_attr, entry|
          return true if storage_attr == entry.storage_attr
        end

        false
      end

      # Returns a column name for an entity's attribute
      #
      # @raise [RuntimeError] when entity not found
      # @raise [RuntimeError] when attr not found
      #
      # @param entity [String] name of the entity
      # @param attr [String] name of the attribute
      # @return [String]
      def storage_attr(domain_name, domain_attr)
        find(domain_name, domain_attr).storage_attr
      end

      # Returns the storage class based on type
      #
      # @raise [RuntimeError] when entity not found
      # @raise [RuntimeError] when attr not found
      # @raise [Dry::Contriner::Error] when db_class is not registered
      #
      # @param entity [String] name of the entity
      # @param attr [String] name of the attribute
      # @return [Object]
      def storage_class(domain_name, domain_attr, type)
        entry = find(domain_name, attr)
        name  = entry.persistence[type]
        key   = "persistence.#{type}.#{name}"
        Appfuel.app_container(root_name)[key]
      end

      private
      def validate_domain(domain_name)
        unless domain_name?(domain_name)
          fail "Domain (#{domain_name}) is not registered"
        end
      end

      def mappings_from_container
        container = Appfuel.app_container(container_root_name)
        container[:repository_mappings]
      end
    end
  end
end
