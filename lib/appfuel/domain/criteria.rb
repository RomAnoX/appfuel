module Appfuel
  module Domain

    # The Criteria represents the interface between the repositories and actions
    # or commands. The allow you to find entities in the application storage (
    # a database) without knowledge of that storage system. The criteria will
    # always refer to its queries in the domain language for which the repo is
    # responsible for mapping that query to its persistence layer.
    class Criteria
      include DomainNameParser

      DEFAULT_PAGE = 1
      DEFAULT_PER_PAGE = 20

      attr_reader :domain, :domain_name, :feature, :repo_name, :exprs, :order,
        :exists, :exec, :all

      # Parse out the domain into feature, domain, determine the name of the
      # repo this criteria is for and initailize basic settings.
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
      def initialize(domain, opts = {})
        @feature, @domain, @domain_name = parse_domain_name(domain)
        @exists       = nil
        @exprs        = []
        @order        = []
        @limit        = nil
        @exec         = nil
        @all          = false
        @first        = false
        @last         = false
        @params       = {}
        @page         = DEFAULT_PAGE
        @per_page     = DEFAULT_PER_PAGE
        @disable_pagination = opts[:disable_pagination] == true
        @repo_name    = "#{(opts[:repo] || @domain).classify}Repository"

        empty_dataset_is_valid!
        if opts[:error_on_empty] == true
          error_on_empty_dataset!
        end

        # default is to expect a collection for this critria unless you declare
        # you want a single
        collection
        public_send(:first) if opts[:single] == true || opts[:first] == true
        public_send(:last)  if opts[:last] == true
      end

      # Add param to the instantiated criteria
      #
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

      # Remove operators and keep key filters. It returns a cleaned
      # list of filters.
      #
      # @example
      #   criteria.filter([
      #     {projects.offer.id: 6},
      #     {last_name: 'SirFooish', op: 'like'},
      #     {first_name: Bob, op: 'like', or: false}
      #   ])
      #
      # @raise [RuntimeError] when the attribute is not an array
      # @raise [RuntimeError] when the filter is not a Hash
      #
      # @param list [Array<Hash>] The list of filters to implement in criteria
      # @return [Array<Hash>, nil] List of filters with values or nil in case of array empty
      def filter(list)
        fail 'the attribute must be an Array' unless list.is_a? Array

        list.each do |item|
          fail 'filters must be a Hash' unless item.is_a? Hash

          operator      = extract_relational_operator(item)
          relational_or = extract_relational_condition(item)
          key, value    = item.first

          where(key, operator => value, or: relational_or)
        end
      end

      def where?
        !exprs.empty? || all?
      end

      # Adds an expression to the list that will be joined to
      # the next expression with an `:and` operator
      #
      # @param domain_attr [String]
      # @param data [Hash]
      # @option <operator> the key is the operator like :eq and value is value
      # @option :or  with a value of true will join this expression with the
      #              previous expression using a relation or. relation and
      #              is by default
      #
      # @return [Criteria]
      def where(domain_attr, data)
        domain_attr = domain_attr.to_s

        relational_op = :and
        if data.key?(:or)
          value = data.delete(:or)
          relational_op = :or if value == true
        end

        domain_entity = domain_name
        if domain_attr.count('.') == 2
          domain_entity, domain_attr = parse_domain_attr(domain_attr)
        end

        expr = {
          expr: create_expr(domain_entity, domain_attr, data),
          relational_op: relational_op
        }
        exprs << expr
        self
      end

      alias_method :and, :where

      # Adds an expression to the list that will be joined to
      # the next expression with an `:or` operator
      #
      # @param attr [String]
      # @param value [Hash]
      # @return [Criteria]
      def or(domain_attr, data)
        data[:or] = true
        where(domain_attr, data)
      end

      # Adds an expression to order list.
      #
      # @param list [list]
      # @return [Criteria]
      def order_by(dict, order_dir = 'ASC')
        if dict.is_a?(String) || dict.is_a?(Symbol)
          dict = {dict.to_s => order_dir}
        end

        dict.each do |domain_attr, dir|
          domain_entity = domain_name

          if domain_attr.count('.') == 2
            domain_entity, domain_attr = parse_domain_attr(domain_attr)
          end

          @order <<  create_expr(domain_entity, domain_attr, eq: dir.to_s.upcase)
        end

        self
      end

      def order?
        !@order.empty?
      end

      def limit?
        !@limit.nil?
      end

      # @param limit [Integer]
      # @return [Criteria]
      def limit(value = nil)
        return @limit if value.nil?

        value = Integer(value)
        fail "limit must be an integer gt 0" unless value > 0
        @limit = value
        self
      end

      # @param page [Integer]
      # @return [Criteria]
      def page(value = nil)
        return @page if value.nil?

        @page = Integer(value)
        self
      end

      # @param per_page [Integer]
      # @return [Criteria]
      def per_page(value=nil)
        return @per_page if value.nil?

        @per_page = Integer(value)
        self
      end

      # The repo uses this to determine what kind of dataset to return
      #
      # @return [Boolean]
      def single?
        first? || last?
      end

      # Tell the repo to only return a single entity for this criteria
      #
      # @return [Criteria]
      def single
        first
        self
      end

      # Set false @first and @last instance variables
      def clear_single
        clear_first
        clear_last
      end

      def first
        @first = true
        clear_last
        self
      end

      def first?
        @first
      end

      def clear_first
        @first = false
      end

      def last?
        @last
      end

      def last
        clear_first
        @last = true
        self
      end

      def clear_last
        @last = false
      end

      def disable_pagination?
        @disable_pagination
      end

      def disable_pagination
        @disable_pagination = true
      end

      # Tell the repo to return a collection for this criteria. This is the
      # default setting
      #
      # @return Criteria
      def collection
        clear_single
        self
      end

      def all?
        @all
      end

      # Tell the repo to return all records for this criteria. It is import
      # to understand that for database queries you are calling all on the
      # map for the specified domain.
      #
      # @example
      #   Criteria.new('projects.offer').all
      #
      #   UserRepository has a mapper with a map for 'offer' in this case
      #   all will be called on the db class for this map.
      #
      # @return [Criteria]
      def all
        @all = true
        collection
        self
      end

      # Used to determin if this criteria belongs to a feature
      #
      # @return [Boolean]
      def feature?
        !@feature.nil?
      end

      # Used to determin if this criteria belongs to a global domain
      #
      # @return [Boolean]
      def global_domain?
        !feature?
      end

      # Determines if a domain exists in this repo
      #
      # @param attr [String]
      # @param value [Mixed]
      # @return [Criteria]
      def exists(domain_attr, value)
        domain_attr   = domain_attr.to_s
        domain_entity = domain_name
        if domain_attr.count('.') == 3
          domain_entity, domain_attr = parse_domain_attr(domain_attr)
        end
        @exists = create_expr(domain_entity, domain_attr, eq: value)
        self
      end

      # @return [DbEntityExpr]
      def exists_expr
        @exists
      end

      # exec is used to indicate we want a custom method on the repo
      # to used with this criteria
      #
      # @param name [String]
      # @return [String, Criteria] when used as a dsl it returns the criteria
      def exec(name = nil)
        return @exec if name.nil?

        @exec = name.to_sym
        self
      end

      def exec?
        !@exec.nil?
      end

      # @yield  expression and operator
      # @return [Enumerator] when no block is given
      def each
        return exprs.each unless block_given?

        exprs.each do |expr|
          yield expr[:expr], expr[:relational_op]
        end
      end

      def error_on_empty_dataset?
        @error_on_empty
      end

      # Tells the repo to return an error when entity is not found
      #
      # @return Criteria
      def error_on_empty_dataset!
        @error_on_empty = true
        self
      end

      # Tells the repo to return and empty collection, or nil if single is
      # invoked, if the entity is not found
      #
      # @return Criteria
      def empty_dataset_is_valid!
        @error_on_empty = false
        self
      end

      private
      def parse_domain_name(name)
        if !name.is_a?(String) && !name.respond_to?(:domain_name)
          fail "domain name must be a string or implement method :domain_name"
        end

        name = name.domain_name if name.respond_to?(:domain_name)
        feature, domain = name.split('.', 2)
        if domain.nil?
          domain  = feature
          feature = nil
        end
        [feature, domain, name]
      end

      def create_expr(domain_name, domain_attr, value)
        Expr.new(domain_name, domain_attr, value)
      end

      def extract_relational_condition(filter_item)
        relational_or = (filter_item.delete(:or) == true) if filter_item.key?(:or)
        relational_or
      end

      def extract_relational_operator(filter_item)
        operator = "eq"
        operator = filter_item.delete(:op) if filter_item.key?(:op)
        if filter_item[:insensitive]
          operator = "ilike"
          filter_item.delete(:insensitive)
        end
        operator
      end
    end
  end
end
