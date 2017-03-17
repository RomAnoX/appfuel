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

      def entity_expr(expr, results = {})
        column = registry.column(expr.domain, expr.original_attr)
        results[column] = expr_value(expr)
        results
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

      def db_where(relation, expr)
        columns = entity_expr(expr)
        if expr.negated?
          return relation.where.not(columns)
        end

        relation.where(columns)
      end

      def expr_value(expr)
        value = expr.value
        method = "#{expr.op}_value"
        return value unless respond_to?(method)

        send(method, value)
      end

      def gt_value(value)
        value + 1 ... Float::INFINITY
      end

      def gteq_value(value)
        value ... Float::INFINITY
      end

      def lt_value(value)
        Float::INFINITY ... value
      end

      def lteq_value(value)
        Float::INFINITY .. value
      end

      def to_db(domain, opts = {})
        excluded = opts[:exclude] || {}
        data   = {}
        domain.undefined_as_nil?

        each_entity_attr(domain.domain_name) do |attr, map_entry|
          column   = map_entry.db_column
          db_class = map_entry.db_class
          next if excluded.include(column)
          next if map_entry.skip_to_db?

          data[db_class] = {} unless data.key?(db_class)
          data[db_class][column] = entity_value(domain, map_entry)
        end
        data
      end

      def entity_value(domain, map_entry)
        value = retieve_entity_value(map_entry.entity_attr)
        if map_entry.computed_attr?
          value = map_entry.compute_attr(value)
        end

        value = nil if undefined?(value)

        value
      end

      def undefined?(value)
        value == Types::Undefined
      end

      #
      # project.offer.union.id
      # foo.bar.baz
      #
      def retrieve_entity_value(domain, entity_attr)
        chain  = map_entry.entity_attr.split('.')
        target = domain
        chain.each do |attr_method|
          unless target.respond_to?(attr_method)
            return nil
          end

          target = target.send_public(attr_method)
        end
        target
      end

      def to_entity(entity, relation, results = {})
        fail "this is no longer implemented see builder pattern"
      end
    end
  end
end
