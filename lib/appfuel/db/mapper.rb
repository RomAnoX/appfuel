module Appfuel
  module Db
    module Mapper
      # Returns the db model that this
      #
      # @raise [RuntimeError] if entity key does not exist
      # @raise [RuntimeError] if map key does not exist
      #
      # @param entity [String] encoded "feature.entity"
      # @param domain_attr [String] attribute of entity
      # @return [DbModel]
      def db_class_mapped(domain_name, domain_attr)
        registry.storage_class_mapped(:db, domain_name, domain_attr)
      end

      def db_class(key)
        registry.storgage_class(:db, key)
      end

      # Resolve the domain expresion into table name and column name
      #
      # @param expr [Appfuel::Domain::Expr]
      # @return [Array] table name, column name
      def db_table_column(expr)
        entry = registry.find(expr.domain_name, expr.domain_attr)
        db    = db_class(entry.persistence[:db])
        [db.table_name, entry.db_column]
      end

      # Resolve the mapped db column to a string in the form of "table.column"
      #
      # @param expr [Appfuel::Domain::Expr]
      # @return [String]
      def qualified_db_column(expr)
        table, column = db_table_column(expr)
        "#{table}.#{column}"
      end

      def exists?(criteria)
        domain_expr = criteria.exists_expr
        domain_name = domain_expr.domain_name
        domain_attr = domain_expr.domain_attr

        db_expr  = create_db_expr(domain_name, domain_attr)
        db_model = db_class_mapped(domain_name, domain_attr)
        db_model.exists?([db_expr.string, db_expr.values])
      end
    end
  end
end
