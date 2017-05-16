require 'parslet'

module Appfuel
  module Domain
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
        left  = data[:left]
        right = data[:right]

        if left.key?(:root)
          left = left[:root]
        elsif left.key?(:domain_expr)
          left = left[:domain_expr]
        elsif left.key?(:and) || left.key?(:or)
          child_op = left.key?(:and) ? 'and' : 'or'
          left = build_conjunction(child_op, left)
        end

        if right.key?(:root)
          right = right[:root]
        elsif right.key?(:domain_expr)
          right = right[:domain_expr]
        elsif right.key?(:and) || right.key?(:or)
          child_op = right.key?(:and) ? 'and' : 'or'
          right = build_conjunction(child_op, right)
        end

        ExprConjunction.new(op, left, right)
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
