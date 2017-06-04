module Appfuel
  module Repository

    # The Criteria represents the interface between the repositories and actions
    # or commands. The allow you to find entities in the application storage (
    # a database) without knowledge of that storage system. The criteria will
    # always refer to its queries in the domain language for which the repo is
    # responsible for mapping that query to its persistence layer.
    #
    # global.user
    # memberships.user
    #
    # exist: 'foo.bar exists id = 6'
    # search: 'foo.bar filter id = 6 and bar = "foo" order id asc limit 6'
    #
    # search:
    #   domain: 'foo.bar',
    #
    #   filters: 'id = 6 or id = 8 and id = 9'
    #   filters: [
    #     {attr: 'id', op: 'eq', value: 999},
    #   ]
    #
    #   order: 'foo.bar.id asc'
    #   order: 'foo.bar.id'
    #   order: [
    #     'foo.bar.id',
    #     {desc: 'foo.bar.id'},
    #     {asc: 'foo.bar.id'}
    #   ]
    #   limit: 1
    #
    class Criteria
      include Appfuel::Domain::DomainNameParser
      attr_reader :domain_basename, :domain_name, :feature, :filters, :order_by


      #
      # 1) Inputs form the SearchTransform.apply
      #    search:
      #       domain:   [String],
      #       filters:  [Expr|ExprConjunction]
      #       orders:   [OrderExpr|Array[OrderExpr]]
      #       limit:    [Integer]
      #
      # 2) Inputs manually built from a developer
      #   search:
      #     domain:   [String],
      #     filters:  [String|Array[String|Hash]]
      #     orders:   [String|Array[String|Hash]]
      #     limit:    [Integer]
      #
      #
      # 3) Inputs as a full search string
      #   search: [String]
      #
      # domain: String,
      # filters: String | Expr | ExprConjunction
      # order: String | Array[OrderExpr|String|Hash]
      # limit: Integer
      #
      #
      def self.build(inputs)
        unless inputs.key?(:domain)
          fail "search criteria :domain is required"
        end
        criteria = self.new(inputs[:domain])
        criteria.filter(inputs[:filters])

        if inputs.key?(:order)
          criteria.order(inputs[:order])
        end

        if inputs.key?(:limit)
          criteria.limit(inputs[:limit])
        end
        criteria
      end

      # Parse out the domain into feature, domain, determine the name of the
      # repo this criteria is for and initailize basic settings.
      # global.user
      #
      # membership.user
      # foo.id filter name like "foo" order foo.bar.id asc limit 2
      # foo.id exists foo.id = 5
      #
      # @example
      #   SpCore::Domain::Criteria('foo', single: true)
      #   Types.Criteria('foo.bar', single: true)
      #
      # === Options
      #   error_on_empty:   will cause the repo to fail when query returns an
      #                     an empty dataset. The failure will have the message
      #                     with key as domain and text is "<domain> not found"
      #
      #   single:           will cause the repo to return only one, the first,
      #                     entity in the dataset
      #
      # @param domain [String] fully qualified domain name
      # @param opts   [Hash] options for initializing criteria
      # @return [Criteria]
      def initialize(domain_name, data = {})
        @feature, @domain_basename, @domain_name = parse_domain_name(domain_name)
        @filters   = nil
        @params    = {}
        @parser    = data[:expr_parser]    || ExprParser.new
        @transform = data[:expr_transform] || ExprTransform.new
        @limit     = nil
        @order_by  = []
        filter(data[:filters]) if data[:filters]
      end

      def clear_filters
        @filters = nil
      end

      def filters?
        !filters.nil?
      end

      def global?
        !feature?
      end

      def feature?
        @feature != 'global'
      end

      # @example
      #   criteria.add_param('foo', 100)
      #
      # @param key [Symbol, String] The key name where we want to keep the value
      # @param value [String, Integer] The value that belongs to the key param
      # @return [String, Integer] The saved value
      def add_param(key, value)
        fail 'key should not be nil' if key.nil?

        @params[key.to_sym] = value
      end

      # @param key [String, Symbol]
      # @return [String, Integer, Boolean] the found value
      def param(key)
        @params[key.to_sym]
      end

      # @param key [String, Symbol]
      # @return [Boolean]
      def param?(key)
        @params.key?(key.to_sym)
      end

      # @return [Boolean] if the @params variable has values
      def params?
        !@params.empty?
      end

      # [
      #   'id = 6',
      #   {'name like "foo"' => 'or'},
      # ]
      #
      #
      def filter_array(input)
        unless input.respond_to?(:each)
          fail "input must implement :each, expecting a list"
        end

        input.each do |item|
          filter(item)
        end
      end

      def filter_string(expr, op: 'and')
        expr = parse_expr(expr)
        fail "Could not parse (#{expr}) unkown failure" unless expr
        filter_expr(expr, op: op)
        self
      end

      #
      # filters: {
      #  'id = 6' => :and,
      #  'id = 8' => :and,
      # }
      def filter_hash(input)
        unless input.respond_to?(:each)
          fail "input must implement :each, expecting a hash"
        end

        input.each do |expr, op|
          filter_string(expr, op: op)
        end

        self
      end

      def filter_expr(expr, op: 'and')
        expr = qualify_expr(expr)
        if filters?
          expr = expr_conjunction_class.new(op, filters, expr)
        end
        @filters = expr
        self
      end

      def filter(item, op: 'and')
        case
        when item.is_a?(Array)  then filter_array(item)
        when item.is_a?(Hash)   then filter_hash(item)
        when item.is_a?(String) then filter_string(item, op: op)
        when item.instance_of?(expr_class),
             item.instance_of?(expr_conjunction_class)
          filter_expr(item, op: op)
        else
          fail "filter could not understand input (#{input})"
        end
        self
      end

      def limit?
        !@limit.nil?
      end

      def limit(nbr = nil)
        return @limit if nbr.nil?

        @limit = Integer(nbr)
        fail "limit must be an integer greater than 0" unless nbr > 0
        self
      end

      def order?
        !@order_by.empty?
      end

      # order first_name asc, last_name
      #   order: 'foo.bar.id asc'
      #   order: 'foo.bar.id'
      #   order: [
      #     'foo.bar.id',
      #     'foo.bar.id asc',
      #     {'foo.bar.id => 'desc'},
      #     {'foo.bar.code => 'asc'},
      #   ]
      #
      # membership.user.id
      def order(data)
       order_exprs(OrderExpr.build(data))
      end

      def order_expr(expr)
        @order_by << qualify_expr(expr)
        self
      end

      def order_exprs(list)
        list.each do |expr|
          order_expr(expr)
        end
        self
      end

      private
      attr_reader :parser, :transform

      def expr_class
        Expr
      end

      def expr_conjunction_class
        ExprConjunction
      end

      def parse_expr(str)
        if !(parser && parser.respond_to?(:parse))
          fail "expression parser must implement :parse"
        end

        if !(transform && transform.respond_to?(:apply))
          fail "expression transform must implement :apply"
        end

        begin
          tree = parser.parse(str)
        rescue Parslet::ParseFailed => e
          msg = "The expression (#{str}) failed to parse"
          err = RuntimeError.new(msg)
          err.set_backtrace(e.backtrace)
          raise err
        end

        result = transform.apply(tree)
        result = result[:domain_expr] || result[:root]
        unless result
          fail "unable to parse (#{str}) correctly"
        end
        result
      end

      def qualify_expr(domain_expr)
        return domain_expr if domain_expr.qualified?
        if global?
          domain_expr.qualify_global(domain_basename)
          return domain_expr
        end

        domain_expr.qualify_feature(feature, domain_basename)
        domain_expr
      end
    end
  end
end
