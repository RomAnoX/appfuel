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
        in:       'IN',
        like:     'LIKE',
        ilike:    'ILIKE',
        between:  'BETWEEN'
      }
      attr_reader :feature, :domain_basename, :domain_name, :domain_attr, :value

      # Assign the fully qualified domain name, its basename and its attribute
      # along with the operator and value. Operator and value are assumed to
      # be the first key => value pair of the hash.
      #
      # @example
      #   feature domain
      #   Expr.new('foo.bar', 'id', eq: 6)
      #
      #   or
      #   global domain
      #   Expr.new('bar', 'name', like: '%Bob%')
      #
      #
      # @param domain [String] fully qualified domain name
      # @param domain_attr [String, Symbol] attribute name
      # @param data [Hash] holds operator and value
      # @option data [Symbol] the key is the operator and value is the value
      #
      # @return [Expr]
      def initialize(domain, domain_attr, data)
        fail "operator value pair must exist in a hash" unless data.is_a?(Hash)
        @feature, @domain_basename, @domain_name = parse_domain_name(domain)

        operator, value = data.first
        @domain_attr    = domain_attr.to_s
        self.op         = operator
        self.value      = value

        fail "domain name can not be empty" if @domain_name.empty?
        fail "domain attribute can not be empty" if @domain_attr.empty?
      end

      def feature?
        !@feature.nil?
      end

      def global?
        !feature?
      end

      # @return [Bool]
      def negated?
        @negated
      end

      def expr_string
        data = yield domain_name, domain_attr, OPS[op]
        lvalue   = data[0]
        operator = data[1]
        rvalue   = data[2]

        operator = "NOT #{operator}" if negated?
        "#{lvalue} #{operator} #{rvalue}"
      end

      def to_s
        "#{domain_name}.#{domain_attr} #{OPS[op]} #{value}"
      end

      def op
        negated? ? "not_#{@op}".to_sym : @op
      end

      private

      def op=(value)
        negated, value = value.to_s.split('_')
        @negated = false
        if negated == 'not'
          @negated = true
        else
          value = negated
        end
        value = value.to_sym
        unless supported_op?(value)
          fail "op has to be one of [#{OPS.keys.join(',')}]"
        end
        @op = value
      end

      def value=(data)
        case op
        when :in
          unless data.is_a?(Array)
            fail ":in operator must have an array as a value"
          end
        when :range
          unless data.is_a?(Range)
            fail ":range operator must have a range as a value"
          end
        when :gt, :gteq, :lt, :lteq
          unless data.is_a?(Numeric)
            fail ":gt, :gteq, :lt, :lteq operators expect a numeric value"
          end
        end
        @value = data
      end

      def supported_op?(op)
        OPS.keys.include?(op)
      end
    end
  end
end
