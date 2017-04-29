module Appfuel
  module Repository
    # The mapping registry holds all entity to db mappings. Mappings are
    # contained within a DbEntityMapEntry object and are arranged by
    # entity name. Each entity will hold a hash where the keys are the
    # attribute names and the value is the entry
    class MappingRegistry
        attr_reader :map, :container_root_name

        def initialize(app_name, map)
          @container_root_name = app_name
          @map = map
        end

        # Determine if an entity has been added
        #
        # @param entity [String]
        # @return [Boolean]
        def entity?(domain_name)
          map.key?(domain_name)
        end

        # Determine if an attribute is mapped for a given entity
        #
        # @param entity [String] name of the entity
        # @param attr [String] name of the attribute
        # @return [Boolean]
        def entity_attr?(entity, attr)
          return false unless entity?(entity)
          map[entity].key?(attr)
        end

        # Returns a mapping entry for a given entity
        #
        # @raise [RuntimeError] when entity not found
        # @raise [RuntimeError] when attr not found
        #
        # @param entity [String] name of the entity
        # @param attr [String] name of the attribute
        # @return [Boolean]
        def find(entity, attr)
          validate_entity(entity)

          unless map[entity].key?(attr)
            fail "Entity (#{entity}) attr (#{attr}) is not registered"
          end
          map[entity][attr]
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
        def persistence_attr_mapped?(domain_name, persistence_attr)
          result = false
          each_domain_attr(entity) do |_attr, entry|
            result = true if persistence_attr == entry.persistence_attr
          end
          result
        end

        # Returns a column name for an entity's attribute
        #
        # @raise [RuntimeError] when entity not found
        # @raise [RuntimeError] when attr not found
        #
        # @param entity [String] name of the entity
        # @param attr [String] name of the attribute
        # @return [String]
        def persistence_attr(domain_name, attr)
          find(entity, attr).persistence_attr
        end

        # Returns the db model for a given entity attr
        # container:
        #   domains:
        #     domain_name -> domain
        #    persistence
        #       db:
        #         persistence_name: -> class
        #
        #   container[persistence.db.name]
        #
        # @raise [RuntimeError] when entity not found
        # @raise [RuntimeError] when attr not found
        # @raise [Dry::Contriner::Error] when db_class is not registered
        #
        # @param entity [String] name of the entity
        # @param attr [String] name of the attribute
        # @return [Object]
        def persistence_class(type, domain_name, attr)
          entry = find(domain_name, attr)
          name  = entry.persistence[type]
          key   = "persistence.#{type}.#{name}"
          Appfuel.app_container(root_name)[key]
        end

        private
        def validate_entity(entity)
          unless entity?(entity)
            fail "Entity (#{entity}) is not registered"
          end
        end
    end
  end
end
