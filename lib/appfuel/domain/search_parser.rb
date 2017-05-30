module Appfuel
  module Domain
    class SearchParser < ExprParser
      rule(:filter_identifier) { stri('filter') }
      rule(:order_identifier)  { stri('order') }
      rule(:limit_identifier)  { stri('limit') }

      rule(:order_dir) do
        (stri('asc') | stri('desc')).as(:order_dir)
      end

      rule(:domain_name) do
        attr_label.as(:feature) >> str('.') >> attr_label.as(:basename)
      end

      rule(:limit_expr) do
        (
          limit_identifier >> space >> space? >> integer.as(:value)
        ).as(:limit)
      end

      rule(:order_expr) do
        (
          (domain_attr >> space >> order_dir) | domain_attr
        ).as(:order_expr)
      end

      # order id
      # order id asc
      # order foo.id asc
      # order foo.id, code desc, foo.bar.id asc
      rule(:order_by) do
        (
          order_identifier >> space >> space? >>
          (order_expr >> (comma >> order_expr).repeat).maybe
        ).as(:order)
      end

      rule(:search) do
        (
          domain_name.as(:domain) >> space >> space? >>
          filter_identifier >> space >> space? >>
          or_operation.as(:filters) >> order_by.maybe >> space? >> limit_expr.maybe
        ).as(:search)
      end

      root(:search)
    end
  end
end
