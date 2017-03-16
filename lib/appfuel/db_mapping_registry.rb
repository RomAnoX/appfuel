module Appfuel

  # The mapping registry holds all entity to db mappings
  #
  # project.offer => attr, column, db_class
  #
  # entity => db column
  #
  module DbMappingRegistry

    class << self
      attr_writer :map

      def map
        @map ||= {}
      end

      def <<(entry)
        unless entry.kind_of?(DbEntityMapEntry)
          fail "this registry only accepts Appfuel::DbEntityMapEntry objects"
        end
        entity = entry.entity
        map[entity] = {} unless map.key?(entity)
        entity_entries = map[entity]
        entity_entries[entry.entity_attr] = entry
      end

      def entity?(entity)
        map.key?(entity)
      end

      def entity_attr?(entity, attr)
        return false unless entity?(entity)
        map[entity].key?(attr)
      end

      def find(entity, attr)
        unless entity?(entity)
          fail "Entity (#{entity}) is not registered"
        end

        unless map[entity].key?(attr)
          fail "Entity (#{entity}) attr (#{attr}) is not registered"
        end
        map[entity][attr]
      end

      def each_entity_attr(entity)
        map[entity].each do |attr, entry|
          yield attr, entry
        end
      end

      def column_mapped?(entity, column)
        result = false
        each_entity_attr(entity) do |attr, entry|
          result = true if column == entry.db_column
        end
        result
      end

      def column(entity, attr)
        find(entity, attr).db_column
      end
    end
  end
end
