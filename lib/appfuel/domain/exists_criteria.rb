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
    #
    # exits:
    #   domain: 'foo.bar'
    #   expr: 'id = 6'
    #
    #   settings:
    #     error_on_empty
    #     parser
    #     transform
    #
    #
    class ExistsCriteria < BaseCriteria
      #
      # @param domain [String] fully qualified domain name
      # @param opts   [Hash] options for initializing criteria
      # @return [Criteria]
      def initialize(domain_name, data = {})
        super

        @exprs = nil

        expr(data[:expr]) if data[:filter]
      end

      def expr(str)
        @exprs = parse_expr(str)
        self
      end
    end
  end
end
