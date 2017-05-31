module Appfuel
  module Domain

    # The Criteria represents the interface between the repositories and actions
    # or commands. The allow you to find entities in the application storage (
    # a database) without knowledge of that storage system. The criteria will
    # always refer to its queries in the domain language for which the repo is
    # responsible for mapping that query to its persistence layer.
    #
    # search: 'foo.bar filter id = 6 and bar = "foo" order id asc limit 6'
    #
    #   filters: 'id = 6 or id = 8 and id = 9'
    #   filters: [
    #     'id = 6',
    #     {or: 'id = 8'}
    #     {and: id = 9'}
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
    class SearchCriteria < BaseCriteria
      attr_reader :order_by


      # domain: String,
      # filters: Expr | ExprConjunction
      # order: Array[OrderExpr]
      # limit: Integer
      #
      #
      def self.build(data)
        unless data.key?(:domain)
          fail "search criteria :domain is required"
        end
        criteria = self.new(data[:domain])

        criteria.filter_expr(data[:filters])
        if data.key?(:order)
          criteria.order_exprs(data[:order])
        end

        if data.key?(:limit)
          criteria.limit(data[:limit])
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
      #
      # @param domain [String] fully qualified domain name
      # @param opts   [Hash] options for initializing criteria
      # @return [Criteria]
      def initialize(domain_name, data = {})
        super
        @limit = nil
        @order_by = []
        filter(data[:filter]) if data[:filter]
      end

      def filter_expr(expr, op: 'and')
        expr = qualify_expr(expr)
        if filters?
          expr = ExprConjunction.new(op, filters, expr)
        end
        @filters = expr
        self
      end

      def filter(str, op: 'and')
        expr = parse_expr(str)
        return false unless expr
        filter_expr(expr, op: op)
      end

      def limit(nbr = nil)
        return @limit if nbr.nil?

        @limit = Integer(nbr)
        fail "limit must be an integer greater than 0" unless nbr > 0
        self
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
    end
  end
end
