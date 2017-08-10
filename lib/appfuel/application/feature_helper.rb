module Appfuel
  module Application
    module FeatureHelper
      def feature_initialized?(key)
        key       = extract_feature_name(key)
        flag_key  = "#{key}.initialized"
        container = Appfuel.app_container
        return false unless container.key?(flag_key)

        container[flag_key] == true
      end

      def initialize_feature(key)
        key = extract_feature_name(key)
        container = Appfuel.app_container

        initializer = container[:feature_initializer]
        initializer.call(key, container)
      end

      def extract_feature_name(key)
        return key unless key.include?('.')
        parts = key.split('.')
        parts[0] == 'features' ? parts[1] : parts[0]
      end
    end
  end
end
