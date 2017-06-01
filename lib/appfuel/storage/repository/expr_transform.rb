module Appfuel
  module Repository
    # A PEG (Parser Expression Grammer) transformer for our domain language.
    #
    class ExprTransform < Parslet::Transform
      rule(integer:  simple(:n))  { Integer(n) }
      rule(float:    simple(:n))  { Float(n) }
      rule(boolean:  simple(:b))  { b.downcase == 'true' }
      rule(datetime: simple(:dt)) { Time.parse(dt) }
      rule(date:     simple(:d))  { Date.parse(d) }
      rule(string:   simple(:s)) do
        s.to_s.gsub(/\\[0tnr]/, "\\0" => "\0",
                                "\\t" => "\t",
                                "\\n" => "\n",
                                "\\r" => "\r")
      end

      rule(domain_expr: subtree(:expr)) do |dict|
        expr  = dict[:expr]
        attrs = build_domain_attrs(expr[:domain_attr])
        op    = expr[:op].to_s.strip.downcase
        value = expr[:value]
        {domain_expr: Expr.new(attrs, op, value)}
      end

      rule(and: subtree(:data)) do |dict|
        {root: build_conjunction('and', dict[:data])}
      end

      rule(or: subtree(:data)) do |dict|
        {root: build_conjunction('or', dict[:data])}
      end

      def self.build_conjunction(op, data)
        left  = build_conjunction_node(data[:left])
        right = build_conjunction_node(data[:right])

        ExprConjunction.new(op, left, right)
      end

      def self.build_conjunction_node(data)
        if data.is_a?(Expr) || data.is_a?(ExprConjunction)
          node = data
        elsif data.key?(:root)
          node = data[:root]
        elsif data.key?(:domain_expr)
          node  = data[:domain_expr]
        elsif data.key?(:and) || data.key?(:or)
          op = data.key?(:and) ? :and : :or
          node = build_conjunction(op, data[op])
        end
        node
      end

      def self.build_domain_attrs(domain_attr)
        attr_list = []
        if domain_attr.is_a?(Hash)
          attr_list << domain_attr[:attr_label].to_s
        else
          domain_attr.each do |label|
            attr_list << label[:attr_label].to_s
          end
        end
        attr_list
      end
    end
  end
end
