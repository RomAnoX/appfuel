module Appfuel
  module Pagination
    # The pager stores the state of a paginated request. It is expected that any
    # criteria that expects a collection will contain a pager. In fact, a criteria
    # will always generate a pager and the repository will choose to use it.
    #
    # NOTE: If you need a collection with all records in one page then use the
    #       :single_page flag, setting it to true.
    #
    class Request < Domain::ValueObject
      attribute 'page',         'form.int', gt: 0, default: 1
      attribute 'per_page',     'form.int', gt: 0, default: 20
      attribute 'sort',         'string'
      attribute 'sort_dir',     enum('asc', 'desc'),  default: 'asc'
      attribute 'single_page',  'bool', default: false

      # Determines if the paginated set is just one page with all records
      #
      # @return [Boolean]
      def single_page?
        single_page == true
      end

      # The pagination interface expects per_page to be nil when you want all
      # records for a single page so we account for this with the single_page?
      # method.
      #
      # @return [Int, Nil]
      def per_page
        return nil if single_page?
        @per_page
      end
    end
  end
end
