module Appfuel
  module Handler
    class Action < Base
      class << self
        def container_class_type
          'actions'
        end

        # In order to reduce the length of namespaces actions are not required
        # to be inside an Actions namespace, but, it is namespaced with in the
        # application container, so we adjust for that here.
        #
        # @return [String]
        def container_relative_key
          "actions.#{super}"
        end
      end

      def dispatch(route, payload = {})
        route = route.to_s
        fail "route can not be empty" if route.empty?

        unless route.include?('/')
          route = "#{self.class.container_feature_name}/#{route}"
        end
        root  = app_container[:root]
        root.call(route, payload)
      end

      def dispatch!(route, payload = {})
        response = dispatch(route, payload)
        fail_handler!(response) if response.failure?

        response.ok
      end
    end
  end
end
