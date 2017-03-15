module Appfuel

  # DbEntityMap is responsible for mapping database column to entity properties.
  # It understands key, value types and format for the map and uses that to
  # convert an entity hash to a db hash and visa versa. It also works with
  # entity expressions and criteria. The map handles only one database table.
  class DbEntityMap
    attr_reader :db_class, :db_class_name, :key

    # Validates the map, ensuring db columns are fully mapped to entity
    # properties. It also adds those properties to the lookup array,
    # resolving hash values into their proper names.
    #
    # NOTE: validating the map is lazy loaded and does not happen until
    #       the map is accessed the first time
    #
    # @param key [String] used to identify this map
    # @param map [Hash] map of column to entity property
    # @param db_class [Appfuel::DbModel] active record db model
    def initialize(key, map, db_class)
      fail ArgumentError, 'map must be a hash' unless map.is_a?(Hash)
      @db_class      = db_class
      @db_class_name = parse_db_name(db_class)
      @lookup        = []
      @map           = map
      @key           = key.to_sym
      @validated     = false
    end

    # NOTE: Validates map before first access
    #
    # @return [Hash]
    # @api public
    def map
      validate! unless validated?
      @map
    end

    # Determine if an entity property is mapped
    # NOTE: will validate the map on first access
    #
    # @api public
    # @param property [String] entity property that is mapped to a column
    # @return [Boolean]
    def attr_mapped?(property)
      validate! unless validated?

      @lookup.include?(property)
    end

    # Determine if a column is mapped
    # NOTE: will validate the map on first access
    #
    # @api public
    # @param column [String] name of the database column
    def column_mapped?(column)
      validate! unless validated?
      map.key?(column)
    end

    def column(entity_attr)
      unless attr_mapped?(entity_attr)
        fail "attribute #{entity_attr} is not mapped"
      end

      map.key(entity_attr)
    end

    # Convert an entity expression into hash with db columns => entity value
    #
    # The expr#original_attr will preserve the (entity.attr) format, when
    # it exists. This will ensure the entity attribute matches
    #
    # @api public
    # @param expr [Appfuel::EntityExpr]
    # @param results [Hash]
    def entity_expr(expr, results = {})
      results[column(expr.original_attr)] = expr_value(expr)

      results
    end

    def expr_value(expr)
      value = expr.value
      case expr.op
      when :gt
        value + 1 ... Float::INFINITY
      when :gteq
        value ... Float::INFINITY
      when :lt
        Float::INFINITY ... value
      when :lteq
        Float::INFINITY .. value
      else
        value
      end
    end
    # Converts a hash of entity attributes into a hash of database columns
    #
    # NOTE: map_each will skip properties mapped as skip or excluded
    #       columns
    #
    #
    # == Options
    # Any column names given as an array with key :exclude will not
    # be processed
    #
    # Example
    #   map.to_db(foo, exclude: ['id', 'other_id'])
    #
    #
    # @api public
    # @param domain [Hash] entity attributes
    # @param opts [Hash] allows you to exclude certain attributes
    # @return [Hash]
    def to_db(domain, opts = {})
      data = {}
      map_each(opts) do |db_column, property|
        value = entity_value(domain, property)
        data[db_column] = value
      end
      data
    end

    # Converts an active record relation to an entity hash
    #
    # == Options
    # Any column names given as an array with key :exclude will not
    # be processed
    #
    # Example
    #   map.to_entity(foo, exclude: ['id', 'other_id'])
    #
    # @api public
    # @param relation [ActiveRecord::Relation]
    # @param results [Hash] add mapped results to
    # @return [Hash]
    def to_entity(relation, opts = {})
      results = opts[:results] || {}
      fail "option results must be a hash" unless results.is_a?(Hash)

      opts[:column_symbols] = true
      data = relation.entity_attributes
      map_each(opts) do |db_column, property|
        next unless data.key?(db_column)
        value = data[db_column]

        entity, property = normalize_property(db_column, property)

        if entity.nil? || entity == key
          results[property] = value
          next
        end

        results[entity] = {} unless results.key?(entity)
        results[entity][property] = value
      end
      results
    end

    def where(expr, op, relation = nil)
      relation ||= db_class
      if op == :or
        relation = relation.or(db_where(relation, expr))
      else
        relation = db_where(relation, expr)
      end
      relation
    end

    private

    def map_each(opts = {})
      exclude = opts[:exclude] || []
      exclude.map!(&:to_s)
      columns_as_symbols = opts[:column_symbols] == true ? true : false
      map.each do |column, property|
        next if exclude.include?(column)
        next if property.is_a?(Hash) && property[:skip] == true

        column = column.to_sym if columns_as_symbols

        yield column, property
      end
    end

    def normalize_property(column, property)
      if property.is_a?(Hash)
        property = property.key?(:name) ? property[:name] : column
      end
      parse_attr_string(property)
    end

    # Convert the entity's mapped attribute into entity name, property.
    # When the property is form the main entity it does not need a name
    #
    # @param property [String]
    # @return [Array] entity name and its property
    def parse_attr_string(property)
      entity, property = property.split('.', 2)
      if property.nil?
        property = entity
        entity = nil
      end
      property = property.to_sym
      entity   = entity.to_sym unless entity.nil?
      [entity, property]
    end

    def entity_value(domain, property)
      value = nil
      if property.is_a?(Hash)
        value = property[:call].call
      else
        value = handle_entity_value(domain, property)
      end

      value = nil if value == Types::Undefined
      value
    end

    def db_where(relation, expr)
      columns = entity_expr(expr)
      if expr.negated?
        relation.where.not(columns)
      else
        relation.where(columns)
      end
    end

    def parse_db_name(name)
      name.to_s.split('::').last.underscore
    end

    # Extracts the value of a property from an entity
    #
    # @api private
    # @param property [Symbol] name of the entity property after its processed
    # @param data [Hash] entity hash data
    def handle_entity_property(property, data)
      unless data.key?(property)
        fail "#{key}: (#{property}) not found"
      end

      data[property]
    end

    # Extracts the value of a property from the child entity
    #
    # @api private
    # @param property [Symbol] name of the entity property after its processed
    # @param child [Symbol] name of the entity
    # @param data [Hash] entity hash data
    def handle_child_entity_property(property, child, data)
      unless data.key?(child)
        fail "#{key}: child (#{child}) not found"
      end

      data = data[child]
      unless data.key?(property)
        fail "#{key}: child (#{child}) property (#{property}) not found"
      end
      data[property]
    end

    # Extract property value of an entity. The entity data is expected
    # as a hash and it handles the following cases
    #
    # 1. property has no entity specified like 'id'
    #    where id is key in the hash
    #    {id: 1234}
    #
    # 2. property has an entity specified like 'foo.id'
    #    where id is a key in the hash of foo
    #     {
    #       foo: {
    #         id: 1234
    #       }
    #     }
    #
    # @api private
    # @param data [Hash] entity hash
    # @param property [String] name of property as seen in the map
    # @return the value found for that property
    def handle_entity_value(data, property)
      entity_name, property = parse_attr_string(property)

      # property belongs to the entity itself, in this case entity_name is
      # the property
      return handle_entity_property(property, data) if entity_name.nil?

      # when key exists we are handling a child entity
      data = data[key] if data.key?(key)

      if entity_name != key
        return handle_child_entity_property(property, entity_name, data)
      else
        return handle_entity_property(property, data)
      end
    end

    def validated?
      @validated
    end

    # validate we actually mapped all the columns then store attribute
    # names in an easy lookup array
    def validate!
      @db_class.column_names.each do |name|
        unless @map.key?(name)
          fail "db model (#{db_class}) column #{name} not mapped"
        end
        attr_name = @map[name]
        # mapped attributes can be a proc which is stored as a hash
        attr_name = attr_name[:name] if attr_name.is_a?(Hash)
        @lookup << attr_name
      end
      @validated = true
    end

    def resolve_entity(name)
      unless Types.key?(name)
       fail ArgumentError, "entity for #{name} is not registered in Types"
      end

      Types[name]
    end

    def resolve_db(name)
      unless Types::Db.key?(name)
       fail ArgumentError, "db model for #{name} is not registered in Types::Db"
      end

      Types::Db[name]
    end

    def parse_entity_name(name)
      fail "entity name can not be empty" if name.empty?
      name = name.split('.').last
      name.strip!

      fail "entity basename can not be empty" if name.empty?
      name
    end
  end
end
