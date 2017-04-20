module Appfuel
  module Feature
    class Initializer
      def call(name, container)
        feature_key = "features.#{name.to_s.underscore}"
        unless container.key?(feature_key)
          Appfuel.setup_container_dependencies(feature_key, container)
        end

        disable_loading_key = "#{feature_key}.disable_loading"
        if !container.key?(disable_loading_key) ||
            container[disable_loading_key] != true
          require "#{container[:features_path]}/#{name.underscore}"
        end

        initialized_key = "#{feature_key}.initialized"
        if !container.key?(initialized_key) ||
            container[initialized_key] != true
          Appfuel.run_initializers(feature_key, container)
        end
      end
    end
  end
end
