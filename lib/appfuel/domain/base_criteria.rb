module Appfuel
  module Domain

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
    #
    #   settings:
    #     page: 1
    #     per_page: 2
    #     disable_pagination
    #     first
    #     all
    #     last
    #     error_on_empty
    #     parser
    #     transform
    #
    # exists:
    #   domain:
    #   expr:
    #
    #
    class BaseCriteria
      include DomainNameParser


      attr_reader :domain_basename, :domain_name, :feature, :settings, :filters

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
        @settings = data[:settings] || CriteriaSettings.new(data)
        @filters  = nil
        @params   = {}
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

      private
      def parse_expr(str)
        if !(settings.parser && settings.parser.respond_to?(:parse))
          fail "expression parser must implement to :parse"
        end

        if !(settings.transform && settings.transform.respond_to?(:apply))
          fail "expression transform must implement :apply"
        end

        begin
          tree = settings.parser.parse(str)
        rescue Parslet::ParseFailed => e
          msg = "The expression (#{str}) failed to parse"
          err = RuntimeError.new(msg)
          err.set_backtrace(e.backtrace)
          raise err
        end

        result = settings.transform.apply(tree)
        result = result[:domain_expr] || result[:root]
        unless result
          fail "unable to parse (#{str}) correctly"
        end
        result
      end
    end
  end
end
