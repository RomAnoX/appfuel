module Appfuel
  module Domain
    # Domain expressions are used mostly by the criteria to describe filter
    # conditions. The class represents a basic expression like "id eq 6", the
    # problem with this expression is that we need additional information in
    # order to properly map it to something like a db expression. This call
    # ensures that additional information exists. Most importantly we need
    # a fully qualified domain name in the form of "feature.domain".
    class Expr
      include DomainNameParser
      OPS = {
        eq:       '=',
        gt:       '>',
        gteq:     '>=',
        lt:       '<',
        lteq:     '<=',
        in:       'in',
        like:     'like',
        between:  'between'
      }
      attr_reader :domain_attr, :op, :value

      def initialize(domain_attr, op, value)
        @domain_attr = parse_attr(domain_attr)
        @op = op
        @value = value
        fail "domain_attr can not be empty" if @domain_attr.empty?
      end

      def expr_string
        data = yield domain_attr, op
        lvalue   = data[0]
        operator = data[1]
        rvalue   = data[2]

        operator = "NOT #{operator}" if negated?
        "#{lvalue} #{operator} #{rvalue}"
      end

      def to_s
        "#{domain_name}.#{domain_attr} #{OPS[op]} #{value}"
      end

      private
      def parse_attr(data)
        return data if data.is_a?(Array)
        unless data.is_a?(String)
          fail "domain attribute must be an array like ['domain', 'id'], " +
            "or string like (domain.id)"
        end
        data.split('.')
      end

      def supported_op?(op)
        OPS.keys.include?(op)
      end
    end
  end
end
