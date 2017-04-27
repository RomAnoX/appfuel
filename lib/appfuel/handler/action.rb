module Appfuel
  module Handler
    class Action < Base
      class << self

        # In order to reduce the length of namespaces actions are not required
        # to be inside an Actions namespace, but, it is namespaced with in the
        # application container, so we adjust for that here.
        #
        # @return [String]
        def container_relative_key
          "actions.#{super}"
        end
      end
    end
  end
end
