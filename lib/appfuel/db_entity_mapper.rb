module Appfuel
  class DbEntityMapper
    attr_reader :map_class

    # Determines if an domain entity exists for this key
    #
    # @param key [String, Symbol]
    # @return [Boolean]
    def entity_class?(key)
      @mappings.key?(key.to_sym)
    end

    # Retrieve a mapped domain entity
    #
    # @param key [Symbol, String]
    # @return [Entity, FalseClass]
    def entity_class(key)
      key = key.to_sym
      return false unless entity_class?(key)

      @mappings[key.to_sym][:entity]
    end

    # Retrieve a mapped domain entity or throws a RuntimeError if it is not
    # found
    #
    # @raise [RuntimeError] if key does not exist
    # @param key [Symbol, String]
    # @return [Entity]
    def entity_class!(key)
      domain = entity_class(key)
      fail "Entity class not found at key #{key}" unless domain
      domain
    end

    # Determines if the given object is an instance of the entity class found
    # by the given key
    #
    # @raise [RuntimeError] if key does not exist
    # @param key [Symbol, String] key used to identify entity
    # @param object [Entity, Object]
    # @return [Bool]
    def instance_of_entity?(key, object)
      object.instance_of?(entity_class!(key))
    end

    # Return all the maps for a given entity
    #
    # @raise [RuntimeError] if entity key does not exist
    #
    # @param key [Symbol, String] the basename of the entity
    # @return [Hash]
    def entity_maps(key)
      key = key.to_sym
      fail "#{key} is not mapped" unless entity_class?(key)
      @mappings[key][:maps]
    end

    # Return a map for a given entity. The key must be encoded as the basename
    # of the entity followed by a period and then the map key.
    #
    # @example If I want the map :fiz for the entity 'foo.baz' then
    #          my key would be "baz.fiz"
    #
    # @example If I want the map :baz for the entity 'foo.baz' then
    #         my key would be 'baz' or :baz. This is because if no map key
    #         is given in the encoding then it will be assumed that the
    #         map key is the same as the basename of the entity so
    #         'baz' is the same as 'baz.baz'
    #
    # @raise [RuntimeError] if entity key does not exist
    # @raise [RuntimeError] if map key does not exist
    #
    # @param key [String] encoded id 'basename.map_key'
    # @return [DbEntityMap]
    def entity_map(key)
      entity_key, map_key = parse_key(key)
      fail "#{entity_key} is not mapped" unless entity_class?(entity_key)

      map = entity_maps(entity_key)
      unless map.key?(map_key)
        fail "Entity is mapped at (#{entity_key}), but does not " +
                "have map at key (#{map_key})"
      end
      map[map_key]
    end

    # Iterates over the maps of a given entity and yields the map
    # with its key
    #
    # @raise [RuntimeError] if entity key does not exist
    #
    # @param entity_basename [Symbol, String]
    # @yield  [map_key, map]
    def each_map(domain_basename)
      entity_maps(domain_basename).each do |key, map|
        yield key, map
      end
    end

    # Returns the active record model from a map for a given entity
    #
    # @raise [RuntimeError] if entity key does not exist
    # @raise [RuntimeError] if map key does not exist
    #
    # @param key [String] encode "<entity_key>.<map>"
    # @return [DbModel]
    def db_class(key)
      entity_map(key).db_class
    end

    # Return the first domain map that contains the mapped attribute
    #
    # @raise [RuntimeError] when an attribute is not located in any maps
    # @param domain [String] the entity for which maps we want to search
    # @param attr_str [String] the attribute string as it was declared in map
    # @return [DbEntityMap]
    def find_map_for_attr(domain, attr_str)
      each_map(domain) do |key, map|
        return map if map.attr_mapped?(attr_str)
      end

      fail "(#{domain}, #{attr_str}) not mapped"
    end

    # Build a where expression from the mapped db class using the criteria.
    #
    # @param criteria [Criteria]
    # @param relation [DbModel, ActiveRecord::Relation]
    # @return [DbModel, ActiveRecord::Relation]
    def where(criteria, relation = nil)
      domain = criteria.domain
      return entity_map("#{domain}").db_class if criteria.exprs.empty?

      map = nil
      db_model = relation
      criteria.each do |expr, op|
        if map.nil? || !map.attr_mapped?(expr.original_attr)
          map = find_map_for_attr(domain, expr.original_attr)
        end

        db_model = map.where(expr, op, db_model)
      end
      db_model
    end

    # Build an order by expression for the given db relation based on the
    # criteria
    #
    # @param criteria [Criteria]
    # @param relation [DbModel, ActiveRecord::Relation]
    # @return [ActiveRecord::Relation]
    def order(criteria, relation)
      return relation unless criteria.order?

      map = nil
      order_by = {}
      criteria.order.each do |entity_attr, dir|
        if map.nil? || !map.attr_mapped?(entity_attr)
          map = find_map_for_attr(criteria.domain, entity_attr)
        end
        order_by[map.column(entity_attr)] = dir
      end

      relation.order(order_by)
    end

    def to_entity(entity_key, relation, results = {})
      maps    = entity_maps(entity_key)
      results = {}
      maps.each do |key, map|
        db_model_name = map.db_class_name
        db_model = if relation.respond_to?(db_model_name)
                     relation.send(db_model_name)
                   else
                     relation
                   end
        results = map.to_entity(db_model, results: results)
      end

      entity_class(entity_key).new(results)
    end

    def to_db(domain, opts = {})
      exclude_attrs = opts[:exclude] || {}
      data       = {}
      entity_key = domain.basename
      domain     = domain.to_h
      each_map(entity_key) do |key, map|
        excluded  = []
        excluded  = exclude_attrs[key] if exclude_attrs.key?(key)
        data[key] = map.to_db(domain, exclude: excluded)
      end
      data
    end

    protected
    def resolve_db(name)
      unless Types::Db.key?(name)
       fail ArgumentError, "db model for #{name} is not registered in Types::Db"
      end

      Types::Db[name]
    end

    def resolve_entity(name)
      unless Types.key?(name)
       fail ArgumentError, "entity for #{name} is not registered in Types"
      end

      Types[name]
    end

    def add_map(dsl)
      entity_key = dsl.entity_key.to_sym
      unless entity_class?(entity_key)
        entity = resolve_entity(dsl.entity_name)
        @mappings[entity.basename.to_sym] = {
          entity: entity,
          maps: {}
        }
      end

      db = resolve_db(dsl.db_name)
      map  = map_class.new(dsl.map_key, dsl.map_data, db)

      @mappings[entity_key][:maps][map.key] = map
    end

    def get_map(name)
      name = name.to_sym
      unless entity_maps.key?(name)
        fail "map for #{name} not found"
      end
      maps[name]
    end

    def parse_key(key)
      entity_key, map_key = key.to_s.split('.', 2)
      map_key = entity_key if map_key.nil?
      [entity_key.to_sym, map_key.to_sym]
    end
  end
end
