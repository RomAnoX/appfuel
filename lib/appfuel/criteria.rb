module Appfuel
  # The Criteria represents the interface between the repositories and actions
  # or commands. The allow you to find entities in the application storage (
  # a database) without knowledge of that storage system. The criteria will
  # always refer to its queries in the domain language for which the repo is
  # responsible for mapping that query to its persistence layer.
  class Criteria

    class << self
      def find_by_id(domain, value)
        criteria = self.new(domain, single: true)
        criteria.where(:id, eq: value)
      end

      def find_by_id!(domain, value)
        criteria = find_by_id(domain, value)
        criteria.error_on_empty_dataset!
      end
    end

    attr_reader :domain, :domain_name, :feature, :repo_name, :exprs, :order,
                :exists, :exec, :all, :pager

    # Parse out the domain into feature, domain, determine the name of the
    # repo this criteria is for and initailize basic settings.
    #
    # === Options
    #   error_on_empty:   will cause the repo to fail when query returns an
    #                     an empty dataset. The failure will have the message
    #                     with key as domain and text is "<domain> not found"
    #
    #   single:           will cause the repo to return only one, the first,
    #                     entity in the dataset
    #
    # === Example
    #  criteria = Appfuel::Criteria.new('offers.offer')
    #
    # @param domain [String] fully qualified domain name
    # @param opts   [Hash] options for initializing criteria
    # @return [Criteria]
    def initialize(domain, opts = {})
      @feature, @domain, @domain_name = parse_domain_name(domain)
      @exists    = nil
      @exprs     = []
      @order     = {}
      @limit     = nil
      @exec      = nil
      @all       = false
      @pager     = nil
      @repo_name = "#{(opts[:repo] || @domain).classify}Repository"

      empty_dataset_is_valid!
      if opts[:error_on_empty] == true
        error_on_empty_dataset!
      end

      # default is to expect a collection for this critria unless you declare
      # you want a single
      collection
      if opts[:single] == true
        @single = true
      end

      pager(opts[:pager] || create_default_pager)
    end

    # Adds an expression to the list that will be joined to
    # the next expression with an `:and` operator
    #
    # @param attr [String]
    # @param value [Hash]
    # @return [Criteria]
    def where(attr, value)
      exprs << {expr: create_expr(attr, value), op: :and}
      self
    end
    alias_method :and, :where

    # Adds an expression to the list that will be joined to
    # the next expression with an `:or` operator
    #
    # @param attr [String]
    # @param value [Hash]
    # @return [Criteria]
    def or(attr, value)
      exprs.last[:op] = :or
      exprs << {expr: create_expr(attr, value), op: :and}
      self
    end

    # Adds a domain attribute to be ordered by
    #
    # @param name [String]
    # @param dir [Symbol]
    # @return [Criteria]
    def order_by(name, dir = :asc)
      @order[name] = dir == :desc ? :desc : :asc
      self
    end

    def order?
      !@order.empty?
    end

    def limit?
      !@limit.nil?
    end

    def limit(value = nil)
      return @limit if value.nil?

      value = Integer(value)
      fail "limit must be an integer gt 0" unless value > 0
      @limit = value
      self
    end

    def page(page, per_page=nil)
      pager.page = page
      pager.per_page = per_page unless per_page.nil?
      self
    end

    # The repo uses this to determine what kind of dataset to return
    #
    # @return [Boolean]
    def single?
      @single
    end


    # Tell the repo to only return a single entity for this criteria
    #
    # @return Criteria
    def single
      @single = true
      self
    end

    # Tell the repo to return a collection for this criteria. This is the
    # default setting
    #
    # @return Criteria
    def collection
      @single = false
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
    #   Criteria.new('offers.offer').all
    #
    #   UserRepository has a mapper with a map for 'offer' in this case
    #   all will be called on the db class for this map.
    #
    def all
      @all    = true
      @single = false
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
    def exists(attr, value)
      @exists = create_expr(attr, eq: value)
      self
    end

    # @return [DbEntityExpr]
    def exists_expr
      @exists
    end

    def pager(value = nil)
      return @pager if value.nil?
      unless value.instance_of?(Types['pager'])
        fail ":pager must be a global pager entity"
      end

      @pager = value
      self
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
    # @return Enumerator when no block is givenk
    def each
      return exprs.each unless block_given?

      exprs.each do |expr|
        yield expr[:expr], expr[:op]
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

    def create_expr(attr, value)
      EntityExpr.new(attr, value)
    end

    def create_default_pager
      Types['pager'][{}]
    end
  end
end
