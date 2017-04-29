module Appfuel
  module Repository
    module Mapper

      # Determines if an domain entity exists for this key
      #
      # @param key [String, Symbol]
      # @return [Boolean]
      def entity_mapped?(name)
        registry.entity?(name)
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

      # Determine if an entity exists in the database using the criteria.
      #
      # @param criteria [Criteria]
      # @return [Boolean]
      def exists?(criteria)
      end

      # @params value [mixed]
      # @return [Boolean]
      def undefined?(value)
        value == Types::Undefined
      end
    end
  end
end
