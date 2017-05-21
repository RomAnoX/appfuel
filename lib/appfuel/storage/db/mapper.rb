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

      # Converts an entity expression into a valid active record expresion with
      # string expresion (array canditions) and value(s)
      #
      # @param expr [Domain::Expr]
      # @param results [Hash]
      # @return [DbExpr] Returns a valid active record expresion
      def convert_expr(expr, entry = nil)
        column = qualified_db_column(expr, entry)
        op     = expr.op
        arg    = case exp.op
                 when 'in', 'not in' then '(?)'
                 when 'between', 'not between' then '? AND ?'
                 else
                   '?'
                 end
        ["#{column} #{op} #{arg}", expr.value]
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
        db_expr, values = convert_expr(domain_expr, entry)
        db = storage_class_from_entry(entry, :db)

        db.exists?([db_expr, values])
      end

      # Build a where expression from the mapped db class using the criteria.Ï
      #
      # @param criteria [Criteria]
      # @param relation [DbModel, ActiveRecord::Relation]
      # @return [DbModel, ActiveRecord::Relation]
      def where(criteria, relation)
        unless criteria.where?
          fail "you must explicitly call :all when criteria has no exprs."
        end

        criteria.each do |domain_expr, op|
          relation = if op == :or
                        relation.or(db_where(domain_expr, relation))
                      else
                        db_where(domain_expr, relation)
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

      # Convert the entity into a hash of db tables that represent
      # that entity. Each table has its own hash of mapped columns.
      #
      # @param domain [Appfuel::Domain::Entity]
      # @param opts [Hash]
      # @option exclued [Array] list of columns to exclude from mapping
      #
      # @return [Hash] each key is a table with a hash of column name/value
      def to_storage(domain, opts = {})
        excluded = opts[:exclude] || []
        data = {}
        each_entity_attr(domain.domain_name) do |entry|
          column   = entry.storage_attr
          db_class = entry.storage(:db)
          next if excluded.include?(column) || entry.skip?

          data[db_class] = {} unless data.key?(db_class)
          data[db_class][column] = entity_value(domain, entry)
        end
        data
      end

      # Handles entity value by checking if its a computed property,
      # fetching the value and converting undefined values to nil.
      #
      # @param domain [Appfuel::Domain::Entity]
      # @param map_entry [MappingEntity]
      # @return the value
      def entity_value(domain, entry)
        value = retrieve_entity_value(domain, entry.domain_attr)
        if entry.computed_attr?
          value = entry.compute_attr(value)
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

      # Create nested hashes from string
      #
      # @param domain_attr [String]
      # @param entity_value [String]
      # @return [nested hash]
      def create_entity_hash(domain_attr, entity_value)
        domain_attr.split('.').reverse.inject(entity_value) { |a,n| {n => a}}
      end

      def model_attributes(relation)
        ap relation
        relation.attributes.select {|_, value| !value.nil?}
      end
    end
  end
end
