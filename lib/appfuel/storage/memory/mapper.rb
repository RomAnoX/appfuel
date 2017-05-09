module Appfuel
  module Memory
    class Mapper < Appfuel::Repository::Mapper

      def to_storage(domain, opts = {})
        excluded = opts[:exclude] || []

        data = {}
        each_entity_attr(domain.domain_name) do |entry|
          attr_name = entry.storage_attr
          next if excluded.include?(attr_name) || entry.skip?

          data[attr_name] = entity_value(domain, entry)
        end
        data
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
