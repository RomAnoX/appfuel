module Appfuel
  module Db
    module RepositoryQuery


      private

      def validate_query_method(method)
        fail "Could not execute method #{method}" unless respond_to?(method)
      end
    end
  end
end
