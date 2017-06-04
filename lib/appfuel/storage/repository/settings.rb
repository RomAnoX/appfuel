module Appfuel
  module Repository
    # The Criteria represents the interface between the repositories and actions
    # or commands. The allow you to find entities in the application storage (
    # a database) without knowledge of that storage system. The criteria will
    # always refer to its queries in the domain language for which the repo is
    # responsible for mapping that query to its persistence layer.
    #
    #   settings:
    #     page: 1
    #     per_page: 2
    #     disable_pagination
    #     first
    #     last
    #     all
    #     error_on_empty
    #     parser
    #     transform
    #     search_name
    #
    class Settings
      DEFAULT_PAGE = 1
      DEFAULT_PER_PAGE = 20

      attr_reader :parser, :transform

      # @param domain [String] fully qualified domain name
      # @param opts   [Hash] options for initializing criteria
      # @return [Criteria]
      def initialize(settings = {})
        @parser     = settings[:parser]    || SearchParser.new
        @transform  = settings[:transform] || SearchTransform.new


        empty_dataset_is_valid!
        enable_pagination
        disable_all
        disable_first
        disable_last

        if settings[:error_on_empty] == true
          error_on_empty_dataset!
        end

        if settings[:disable_pagination] == true
          disable_pagination
        end

        if settings[:first] == true
          first
        elsif settings[:last] == true
          last
        elsif settings[:all]
          all
        end

        manual_query(settings[:manual_query]) if settings.key?(:manual_query)

        page(settings[:page] || DEFAULT_PAGE)
        per_page(settings[:per_page] || DEFAULT_PER_PAGE)
      end

      def manual_query?
        !manual_query.nil?
      end

      def manual_query(value = nil)
        return @manual_query if value.nil?
        @manual_query = value
        self
      end

      def disable_pagination?
        @disable_pagination
      end

      def enable_pagination
        @disable_pagination = false
        self
      end

      def disable_pagination
        @disable_pagination = true
        self
      end

      def page(value = nil)
        return @page if value.nil?
        @page = Integer(value)
        self
      end

      def per_page(value = nil)
        return @per_page if value.nil?
        @per_page = Integer(value)
        self
      end

      def single?
        first? || last?
      end

      def all?
        @all
      end

      def all
        @all = true
        disable_first
        disable_last
        self
      end

      def first?
        @first
      end

      def first
        @first = true
        disable_last
        disable_all
        self
      end

      def last?
        @last
      end

      def last
        @last = true
        disable_first
        disable_all
        self
      end

      # Tells the repo to return an error when entity is not found
      #
      # @return SearchSettings
      def error_on_empty_dataset!
        @error_on_empty = true
        self
      end

      # Tells the repo to return and empty collection, or nil if single is
      # invoked, if the entity is not found
      #
      # @return SearchSettings
      def empty_dataset_is_valid!
        @error_on_empty = false
        self
      end

      def error_on_empty_dataset?
        @error_on_empty
      end

      private
      def disable_all
        @all = false
      end

      def disable_first
        @first = false
      end

      def disable_last
        @last = false
      end
    end
  end
end
