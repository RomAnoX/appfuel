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

      def to_entity_hash(domain_name,  data)
        entity_attrs = {}
        each_entity_attr(domain_name) do |entry|
          attr_name   = entry.storage_attr
          domain_attr = entry.domain_attr
          next unless data.key?(attr_name)

          value = data[attr_name]
          if domain_attr.include?('.')
            entity_attrs = entity_attrs.deep_merge(create_entity_hash(domain_attr, value))
          else
            entity_attrs[domain_attr] = value
          end
        end

        entity_attrs
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
