module Appfuel
  module Db
    # The mapping registry holds all entity to db mappings. Mappings are
    # contained within a DbEntityMapEntry object and are arranged by
    # entity name. Each entity will hold a hash where the keys are the
    # attribute names and the value is the entry
    module MappingRegistry
      class << self
        attr_writer :map

        def map
          @map ||= {}
        end

        # Adds entry objects to the map. Beacause each entry has its entity
        # name the registry will know where to put the entry
        #
        # @param entry [DbEntityMapEntry]
        # @return [DbEntityMapEntry]
        def <<(entry)
          unless entry.kind_of?(MappingEntry)
            fail "this registry only accepts Appfuel::Db::MappingEntry objects"
          end
          entity = entry.entity
          map[entity] = {} unless map.key?(entity)
          entity_entries = map[entity]
          entity_entries[entry.entity_attr] = entry
        end

        # Determine if an entity has been added
        #
        # @param entity [String]
        # @return [Boolean]
        def entity?(entity)
          map.key?(entity)
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
        def each_entity_attr(entity)
          validate_entity(entity)

          map[entity].each do |attr, entry|
            yield attr, entry
          end
        end

        # Determine if an column is mapped for a given entity
        #
        # @param entity [String] name of the entity
        # @param attr [String] name of the attribute
        # @return [Boolean]
        def column_mapped?(entity, column)
          result = false
          each_entity_attr(entity) do |_attr, entry|
            result = true if column == entry.db_column
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
        def column(entity, attr)
          find(entity, attr).db_column
        end

        # Returns the db model for a given entity attr
        #
        # @raise [RuntimeError] when entity not found
        # @raise [RuntimeError] when attr not found
        # @raise [Dry::Contriner::Error] when db_class is not registered
        #
        # @param entity [String] name of the entity
        # @param attr [String] name of the attribute
        # @return [Object]
        def db_class(entity, attr)
          entry = find(entity, attr)
          Types::Db[entry.db_class]
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
end
