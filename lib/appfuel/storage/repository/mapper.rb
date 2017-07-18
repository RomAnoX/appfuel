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
        if !map.nil? && !map.instance_of?(MappingCollection)
          fail "repository mappings must be a MappingCollection"
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
        map.entity?(entity_name)
      end

      # Determine if an attribute is mapped for a given entity
      #
      # @param entity [String] name of the entity
      # @param attr [String] name of the attribute
      # @return [Boolean]
      def entity_attr?(entity_name, entity_attr, type)
        map.entity_attr?(type, entity_name, entity_attr)
      end

      # Returns a column name for an entity's attribute
      #
      # @raise [RuntimeError] when entity not found
      # @raise [RuntimeError] when attr not found
      #
      # @param entity_name [String] qualified entity name "<feature>.<entity>"
      # @param entity_attr [String] name of the attribute
      # @return [String]
      def storage_attr(entity_name, entity_attr, type)
        map.storage_attr(type, entity_name, entity_attr)
      end

      def storage_key(type, entity_name)
        map.storage_key(type, entity_name)
      end

      def entity_container_name(type, entity_name)
        map.container_name(type, entity_name)
      end

      def storage_map(type, domain_name)
        map.storage_map(type, domain_name)
      end

      # Returns the storage class based on type
      # mapping foo.bar, db: auth.foo_bar,
      #
      # @raise [RuntimeError] when entity not found
      # @raise [RuntimeError] when attr not found
      # @raise [Dry::Contriner::Error] when db_class is not registered
      #
      # @param entity [String] name of the entity
      # @param attr [String] name of the attribute
      # @return [Object]
      def storage_class(type, entity_name)
        key = storage_key(type, entity_name)
        domain_container = entity_container_name(type, entity_name)
        unless container_root_name == domain_container
          fail "You can not access a mapping outside of this container " +
            "(mapper: #{container_root_name}, entry: #{domain_container})"
        end

        fetch_storage_class(key)
      end

      def fetch_storage_class(key)
        app_container = Appfuel.app_container(container_root_name)
        app_container[key]
      end

      def to_entity_hash(domain_name, type, storage)
        entity_attrs = {}
        storage_data = storage_hash(storage)
        map.each_attr(type, domain_name) do |domain_attr, storage_attr, skip|
          next unless storage_data.key?(storage_attr)
          value = storage_data[storage_attr]
          update_entity_hash(domain_attr, value, entity_attrs)
        end
        entity_attrs
      end

      def storage_hash(storage)
        return storage if storage.is_a?(Hash)
        fail "storage must implement to_h" unless storage.respond_to?(:to_h)
        storage.to_h
      end

      # Convert the domain into a hash of storage attributes that represent.
      # Each storage class has its own hash of mapped attributes. A domain
      # can have more than one storage class.
      #
      # @param domain [Appfuel::Domain::Entity]
      # @param type [Symbol] type of storage :db, :file, :memory etc...
      # @param opts [Hash]
      # @option exclued [Array] list of columns to exclude from mapping
      #
      # @return [Hash] each key is a storage class with a hash of column
      #                name/value
      def to_storage(domain, type, opts = {})
        unless domain.respond_to?(:domain_name)
          fail "Domain entity must implement :domain_name"
        end

        excluded     = opts[:exclude] || []
        data         = {}
        domain_name  = domain.domain_name
        map.each_attr(type, domain_name) do |domain_attr, storage_attr, skip|
          next if excluded.include?(storage_attr) || skip == true

          data[storage_attr] = entity_value(domain, domain_attr)
        end

        data
      end

      # user.role.id => user_role_id 99
      #
      # {
      #   user: {
      #     role: {
      #       id: 99
      #       }
      #     }
      #   }
      #
      #  id
      #
      def update_entity_hash(domain_attr, value, hash)
        if domain_attr.include?('.')
          hash.deep_merge!(create_entity_hash(domain_attr, value))
        else
          hash[domain_attr] = value
        end
      end

      def entity_value(domain, domain_attr)
        value = resolve_entity_value(domain, domain_attr)
        value = nil if undefined?(value)

        value
      end

      # user.role.id
      #
      # [id, role, user]
      #
      def create_entity_hash(domain_attr, value)
        domain_attr.split('.').reverse.inject(value) do |result, nested_attr|
          {nested_attr => result}
        end
      end

      def undefined?(value)
        value == Types::Undefined
      end

      def resolve_entity_value(domain, domain_attr)
        chain  = domain_attr.split('.')
        target = domain
        chain.each do |attr_method|
          return nil unless target.respond_to?(attr_method)
          target = target.public_send(attr_method)
        end
        target
      end

      def expr_conjunction?(value)
        value.instance_of?(ExprConjunction)
      end

      private
      def validate_domain(entity_name)
        unless entity?(entity_name)
          fail "Entity (#{entity_name}) is not registered"
        end
      end

      def mappings_from_container
        container = Appfuel.app_container(container_root_name)
        container[:repository_mappings]
      end
    end
  end
end
