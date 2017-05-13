module SpCore
  module Domain

    # CriteriaBuilder is an interface creating new Criteria as well as
    # building up an existing Criteria instance
    class CriteriaBuilder

      # For the list of defined inputs and maps, it builds new Criteria object
      # following build pattern
      #
      # @example
      #
      #   inputs = {
      #     search: "projects.offer",
      #     repo_map: { "projects.offer" => "foo" },
      #     filters: [
      #       {foo: 'bar', ep: 1}
      #     ],
      #     order: [
      #       {created_at: :desc}
      #     ],
      #     limit: 5,
      #     all: true,
      #     page: 1,
      #     per_page: 10
      #   }
      #
      #   maps = {
      #     feature: "projects",
      #     attr_map: {
      #       foo: "users.user.foo"
      #     }
      #   }
      #
      #   criteria_builder = SpCore::Domain::CriteriaBuilder.build(inputs, maps)
      #
      # @param inputs [Hash] input data
      # @param maps [Hash] mapping data
      # @return [Criteria]
      def self.build(inputs, maps = {})
        builder = new(inputs, maps)
        criteria = builder.create
        builder.build(criteria, inputs)
        criteria
      end

      # Builds new Criteria object
      #
      # @param inputs [Hash] input data
      # @option inputs [String] :search entity/domain to search for
      # @option inputs [Hash] :repo_map repository mapping by entity/domain
      # @option inputs [Array] :filters list of filter items
      # @option inputs [Array] :order list of order definitions
      # @option inputs [Integer] :limit number of records to limit to
      # @option inputs [Boolean] :all flag for returning all records
      # @option inputs [Boolean] :first flag for returning only first record
      # @option inputs [Boolean] :last flag for returning only last record
      # @option inputs [Integer] :page number of the page in collection
      # @option inputs [Integer] :per_page num. of items per page in collection
      # @option inputs [Boolean] :single_page flag for getting single page only
      # @param maps [Hash] mapping data
      # @option maps [Hash] :attr_map mapping by attr to domain.attribute_name
      # @return [Criteria]
      def initialize(inputs, maps)
        domain_name   =  inputs.fetch(:search).to_s
        repo_map =       inputs[:repo_map] || {}
        fail ":repo_map must be a Hash" unless repo_map.is_a?(Hash)

        @attr_map =      maps[:attr_map] || {}
        @domain_name   =      "#{domain_name}"
        @repo_name = repo(repo_map, domain_name)
      end

      # Creates new Criteria instance.
      # Actually it's just a delegator to Criteria initializer
      #
      # @param domain [String] fully qualified domain name
      # @param options [Hash] options for initializing Criteria
      # @return [Criteria]
      def create
        Criteria.new(domain_name, repo: repo_name)
      end

      # Build criteria clauses
      #
      # @param inputs [Hash]
      def build(criteria, inputs)
        self.filters(criteria, inputs, attr_map)
            .order(criteria, inputs, attr_map)
            .limit(criteria, inputs)
            .scope(criteria, inputs)
            .pagination(criteria, inputs)
      end

      # Updates Criteria object filters with the list of given filters
      # Each filter item must be a Hash.
      #
      # @example
      #   inputs = {
      #     filters: [
      #       {first_name: 'Bob'},
      #       {last_name: 'Doe', op: 'like'},
      #       {last_name: 'Johnson', op: 'like', or: false}
      #     ]
      #   }
      #
      # @param criteria [Criteria] criteria object to build
      # @param inputs [Hash] input data
      # @option inputs [Array] :filters list of filter items
      # @param attr_map [Hash] mapping by attr to domain.attribute_name
      # @return [CriteriaBuilder]
      def filters(criteria, inputs, attr_map = {})
        if inputs.key?(:filters)
          filters = inputs.fetch(:filters)
          fail ":filters must be an Array" unless filters.is_a?(Array)

          filters.each do |filter_item|
            attr_name, value = filter_item.first
            qualified_name = lookup_attribute(attr_name, attr_map)
            if qualified_name != attr_name
              filter_item.delete(attr_name)
              filter_item[qualified_name] = value
            end
          end

          criteria.filter(filters)
        end
        self
      end

      # Updates given Criteria ordering clause.
      # It expects a list of order definitions.
      # Order definition might be either Hash, String or Symbol.
      # If item is String or Symbol, ordering direction is ascending(:asc)
      #
      # @example
      #   inputs = {
      #     order: [
      #       {created_at: :desc},
      #       'created_at',
      #       :created_at
      #     ]
      #   }
      #
      # @param criteria [Criteria] criteria object to build
      # @param inputs [Hash] input data
      # @option inputs [Array] :order list of order definitions
      # @param attr_map [Hash] mapping by attr to domain.attribute_name
      # @return [CriteriaBuilder]
      def order(criteria, inputs, attr_map = {})
        return self unless inputs.key?(:order)
        list = inputs.fetch(:order)

        fail ":order must implement :each" unless list.respond_to?(:each)
        return self if list.empty?

        final_order = {}
        list.each do |order|
          domain_attr_name = order
          order_dir = "asc"

          if order.is_a?(Hash)
            domain_attr_name, order_dir = order.first
          end

          qualified_name = lookup_attribute(domain_attr_name, attr_map)
          final_order[qualified_name.to_s] = order_dir.to_s
          criteria.order_by(final_order)
        end
        self
      end

      # Updates given Criteria record limit
      #
      # @param criteria [Criteria] criteria to build
      # @param inputs [Hash] input data
      # @option inputs [Integer] :limit number of records to limit to
      # @return [CriteriaBuilder]
      def limit(criteria, inputs)
        if inputs.key?(:limit)
          criteria.limit(inputs.fetch(:limit))
        end
        self
      end

      # Updates given Criteria collection limits.
      # Those are :disable_pagination, :all, :first and :last properties.
      #
      # @param criteria [Criteria] criteria to build
      # @param inputs [Hash] input data
      # @option inputs [Boolean] :all flag for returning all records
      # @option inputs [Boolean] :first flag for returning onnly first record
      # @option inputs [Boolean] :last flag for returning only last record
      # @return [CriteriaBuilder]
      def scope(criteria, inputs)
        if inputs[:first] == true
          criteria.first
        elsif inputs[:last] == true
          criteria.last
        elsif inputs[:disable_pagination] == true
          criteria.disable_pagination
        elsif inputs[:all] == true
          criteria.all
        end
        self
      end

      # Updates given Criteria pagination params.
      #
      # @param criteria [Criteria] criteria to build
      # @param inputs [Hash] input data
      # @option inputs [Integer] :page number of the page within collection
      # @option inputs [Integer] :per_page number of items per page
      # @option inputs [Boolean] :single_page flag for getting single page only
      # @param attr_map [Hash] mapping by attr to domain.attribute_name
      # @return [CriteriaBuilder]
      def pagination(criteria, inputs)
        criteria.disable_pagination           if inputs[:single_page]==true || inputs[:disable_pagination] == true
        criteria.page(inputs[:page])          if inputs[:page]
        criteria.per_page(inputs[:per_page])  if inputs[:per_page]
        self
      end

    private

      attr_reader :attr_map, :domain_name, :repo_name

      def repo(repo_map, domain_name)
        repo_map.key?(domain_name) ? repo_map[domain_name].to_s : domain_name
      end

      # It looks for given attribute name in the mapping and returns
      # domain.attribute_name string if found. Else it returns attribute
      # name itself.
      #
      # @private
      #
      # @param name [String] attribute name
      # @param map [Hash] attribute to domain.attribute_name mapping
      # @return [String]
      def lookup_attribute(name, map)
        return name unless map.is_a?(Hash)
        return name unless map.key?(name) || map.key?(name.to_sym)
        map[name] || map[name.to_sym]
      end
    end
  end
end
