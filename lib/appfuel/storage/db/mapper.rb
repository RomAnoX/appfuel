module Appfuel
  module Db
    class Mapper < Appfuel::Repository::Mapper

      def search(domain_name, criteria, opts = {})

      end

      # Return qualified db column name from entity expression.
      #
      # @param expr [SpCore::Domain::Expr]
      # @return db column name [String]
      def qualified_db_column(expr, entry = nil)
        table_name, column = db_table_column(expr, entry)
        "#{table_name}.#{column}"
      end

      # Determine Domain Mapentry and DbModel from entity expression.
      #
      # @param expr [SpCore::Domain::Expr]
      # @return [table_name, column] [Array]
      def db_table_column(expr, entry = nil)
        entry ||= find(expr.domain_name, expr.domain_attr)
        db  = storage_class_from_entry(entry, :db)

        [db.table_name, entry.storage_attr]
      end

      # Converts an entity expression into a valid active record expresion
      # expression.
      #
      # @param expr [Domain::Expr]
      # @param entry [Repository::MappingEntry] optional
      # @return [Array] The first index is the expr string using ? for values
      #                 The second index is the actual value(s)
      def convert_expr(expr, values = [], entry = nil)
        if expr_conjunction?(expr)
          return convert_conjunction(expr, values, entry)
        end

        column = qualified_db_column(expr, entry)
        op     = expr.op
        arg    = case expr.op
                 when 'in', 'not in' then '(?)'
                 when 'between', 'not between' then '? AND ?'
                 else
                   '?'
                 end

        values << expr.value
        ["#{column} #{op} #{arg}", values]
      end

      def convert_conjunction(expr, values = [], entry = nil)
        left, values  = convert_expr(expr.left, values, entry)
        right, values = convert_expr(expr.right, values, entry)
        ["#{left} #{expr.op} #{right}", values]
      end

      # Validates if a record exists in the table that matches the array with
      # the conditions given.
      #
      # @param criteria [Criteria]
      # @return [Boolean]
      def exists?(domain_expr)
        domain_name = domain_expr.domain_name
        domain_attr = domain_expr.domain_attr

        entry = find(domain_name, domain_attr)
        db_expr, values = convert_expr(domain_expr, [], entry)
        db = storage_class_from_entry(entry, :db)

        db.exists?([db_expr, *values])
      end

      # Build a where expression from the mapped db class using the criteria.Ï
      #
      # @param criteria [Criteria]
      # @param relation [DbModel, ActiveRecord::Relation]
      # @return [DbModel, ActiveRecord::Relation]
      def where(criteria, relation)
        conditions, values = convert_expr(criteria.filters)
        relation.where(conditions, *values)
      end

      # Build an order by expression for the given db relation based on the
      # criteria
      #
      # @param criteria [Criteria]
      # @param relation [DbModel, ActiveRecord::Relation]
      # @return [ActiveRecord::Relation]
      def order(criteria, relation)
        return relation unless criteria.order?
        criteria.order.each do |expr|
          db_column = qualified_db_column(expr)
          direction = expr.value
          relation = relation.order("#{db_column} #{direction}")
        end
        relation
      end

      # Eventhough there is no mapping here we add the interface for
      # consistency.
      #
      # @param criteria [Criteria]
      # @param relation [DbModel, ActiveRecord::Relation]
      # @return [ActiveRecord::Relation]
      def limit(criteria, relation)
        return relation unless criteria.limit?

        relation.limit(criteria.limit)
      end

      # Map the entity expr to a hash of db_column => value and call
      # on the relation using that.
      #
      # @note this is db library specific and needs to be moved to an adapter
      #
      # @param expr [Appfuel::Domain::Expr]
      # @param relation [ActiveRecord::Relation]
      # @return [ActiveRecord::Relation]
      def db_where(domain_expr, relation)
        db_expr = create_db_expr(domain_expr)
        relation.where([db_expr.string, db_expr.values])
      end
    end
  end
end
