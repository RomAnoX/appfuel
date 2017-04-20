module Appfuel
  module Feature
    class ActionLoader
      def call(request, container)
        root = container[:root]
        app_name = container[:app_name]
        feature_class = request.feature
        unless root.const_defined?(feature_class)
          fail "[#{app_name}] Feature #{feature_class} not defined in #{root}"
        end
        feature = root.const_get(feature_class)

        action_class = request.action
        unless feature.const_defined?(action_class)
          fail "[#{app_name}] Action #{action_class} not defined in #{feature}"
        end
        feature.const_get(action_class)
      end
    end
  end
end
