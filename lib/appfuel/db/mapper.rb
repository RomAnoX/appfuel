module Appfuel
  module Db
    module Mapper

      def registry
        MappingRegistry
      end

      # Determines if an domain entity exists for this key
      #
      # @param key [String, Symbol]
      # @return [Boolean]
      def entity_mapped?(name)
        registry.entity?(name)
      end

      # Returns the active record model from a map for a given entity
      #
      # @raise [RuntimeError] if entity key does not exist
      # @raise [RuntimeError] if map key does not exist
      #
      # @param entity [String] encoded "feature.entity"
      # @param attr [String] attribute of entity
      # @return [DbModel]
      def db_class(entity, attr)
        registry.db_class(entity, attr)
      end

      # Converts an entity expression into a hash of db columns with their
      # mapped values
      #
      # @param expr [Domain::Expr]
      # @param results [Hash]
      # @return [Hash]
      def entity_expr(expr, results = {})
        column = registry.column(expr.entity, expr.attr)
        results[column] = expr_value(expr)
        results
      end


      # Build a where expression from the mapped db class using the criteria.
      #
      # @param criteria [Criteria]
      # @param relation [DbModel, ActiveRecord::Relation]
      # @return [DbModel, ActiveRecord::Relation]
      def where(criteria, relation)
        if criteria.exprs.empty? && !criteria.all?
          fail "you must explicitly call :all when criteria has no exprs"
        end

        criteria.each do |expr, op|
          relation = if op == :or
                       relation.or(db_where(relation, expr))
                     else
                       db_where(relation, expr)
                     end
        end
        relation
      end

      # Build an order by expression for the given db relation based on the
      # criteria
      #
      # @param criteria [Criteria]
      # @param relation [DbModel, ActiveRecord::Relation]
      # @return [ActiveRecord::Relation]
      def order(criteria, relation)
        return relation unless criteria.order?

        order_by = {}
        domain   = criteria.domain
        criteria.order.each do |entity_attr, dir|
          column = registry.column(domain, entity_attr)
          order_by[column] = dir
        end

        relation.order(order_by)
      end

      # Map the entity expr to a hash of db_column => value and call
      # on the relation using that.
      #
      # @note this is db library specific and needs to be moved to an adapter
      #
      # @param expr [Appfuel::Domain::Expr]
      # @param relation [ActiveRecord::Relation]
      # @return [ActiveRecord::Relation]
      def db_where(expr, relation)
        columns = entity_expr(expr)
        if expr.negated?
          return relation.where.not(columns)
        end

        relation.where(columns)
      end

      # Run the expr value through a strategy pattern to allow operator
      # specific value validation or modifications
      #
      # @param expr [Domain::Expr]
      # @return [mixed]
      def expr_value(expr)
        value = expr.value
        method = "#{expr.op}_value"
        return value unless respond_to?(method)

        send(method, value)
      end

      # Used by #entity_value this is part of a strategry pattern to make
      # greater than operator work seemlessly with active record.
      #
      # @note db library specific code should be moved to an adapter
      #
      # @param value [Numeric]
      # @return [Range]
      def gt_value(value)
        value + 1 ... Float::INFINITY
      end

      # @see gt_value
      def gteq_value(value)
        value ... Float::INFINITY
      end

      # We don't have to do the + 1 because for less than active record honors
      # inclusive ranges
      #
      # @see gt_value
      def lt_value(value)
        Float::INFINITY ... value
      end

      # @see gt_value
      def lteq_value(value)
        Float::INFINITY .. value
      end

      # Convert the entity into a hash of db tables that represent
      # that entity. Each table has its own hash of mapped columns.
      #
      # @param domain [Appfuel::Domain::Entity]
      # @param opts [Hash]
      # @option exclued [Array] list of columns to exclude from mapping
      #
      # @return [Hash] each key is a table with a hash of column name/value
      def to_db(domain, opts = {})
        excluded = opts[:exclude] || {}
        data   = {}
        domain.undefined_as_nil?

        each_entity_attr(domain.domain_name) do |_attr, map_entry|
          column   = map_entry.db_column
          db_class = map_entry.db_class
          next if excluded.include(column)
          next if map_entry.skip_to_db?

          data[db_class] = {} unless data.key?(db_class)
          data[db_class][column] = entity_value(domain, map_entry)
        end
        data
      end

      # Handles entity value by checking if its a computed property,
      # fetching the value and converting undefined values to nil.
      #
      # @param domain [Appfuel::Domain::Entity]
      # @param map_entry [MappingEntity]
      # @return the value
      def entity_value(domain, map_entry)
        value = retieve_entity_value(domain, map_entry.entity_attr)
        if map_entry.computed_attr?
          value = map_entry.compute_attr(value)
        end

        value = nil if undefined?(value)

        value
      end

      # @params value [mixed]
      # @return [Boolean]
      def undefined?(value)
        value == Types::Undefined
      end

      # Fetch the value for the entity attribute. When the attribute name
      # contains a '.' then traverse the dots and call the last attribute
      # for the value
      #
      # @param domain [Appfuel::Domain::Entity]
      # @param entity_attribute [String]
      # @return the value
      def retrieve_entity_value(domain, entity_attr)
        chain  = entity_attr.split('.')
        target = domain
        chain.each do |attr_method|
          unless target.respond_to?(attr_method)
            return nil
          end

          target = target.public_send(attr_method)
        end
        target
      end

      # This is moved to a builder pattern so a separate object will handle
      # this responsiblity
      #
      # @deprecated
      #
      # @param _entity [String]
      # @param _relation [ActiveRecordRelation]
      # @param _results [Hash]
      # @return [Appfuel::Domain::Entity]
      def to_entity(_entity, _relation, _results = {})
        fail "this is no longer implemented see builder pattern"
      end
    end
  end
end
