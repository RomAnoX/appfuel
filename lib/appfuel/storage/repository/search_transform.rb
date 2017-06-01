module Appfuel
  module Repository
    class SearchTransform <  ExprTransform


      rule(order_dir: simple(:n)) {
        value = n.to_s.downcase
        value == 'desc' ? 'desc' : 'asc'
      }

      rule(order_expr: subtree(:expr)) do |dict|
        expr = dict[:expr]
        domain_attr = expr[:domain_attr]
        order_dir = expr[:order_dir] || 'asc'
        OrderExpr.new(domain_attr, order_dir)
      end

      rule(attr_label: simple(:n)) { n.to_s }

      rule(domain_attr: simple(:n)) {
        list = n.is_a?(Array) ? n : [n]
        {domain_attr: list}
      }

      rule(domain_expr: subtree(:domain_expr)) do |dict|
        data = dict[:domain_expr]
        domain_attr = data[:domain_attr]
        op          = data[:op]
        value       = data[:value]
        Expr.new(domain_attr, op, value)
      end

      rule(search: subtree(:search)) do |dict|
        search  = dict[:search]
        domain  = search[:domain]
        filters = search[:filters]
        orders  = search[:order]
        limit   = search[:limit]

        filters = filters[:root] if filters.key?(:root)
        result  = {}
        result[:domain]  = "#{domain[:feature]}.#{domain[:basename]}"
        result[:filters] = filters
        unless limit.nil?
          result[:limit] = limit[:value]
        end

        unless orders.nil?
          orders = orders.is_a?(Array) ? orders : [orders]
          result[:order] = orders
        end
        {search: Criteria.build(result)}
      end
    end
  end
end
