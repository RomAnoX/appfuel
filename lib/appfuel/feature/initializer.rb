module Appfuel
  module Feature
    # Run a given feature's initializers. Each feature can declare any number
    # of initializers just as the application does. This allow dependencies
    # and vendor code to be initialized only when the feature is used.
    class Initializer
      # Ensure the correct namespaces are registered so that the initializer
      # dsl will work and then require the feature and run its intializers
      # unless instructed not too. Initializers are only run once.
      #
      # @param name [String] name of the feature as found in the container
      # @param container [Dry::Container] application container
      # @return [Boolean]
      def call(name, container)
        name = name.to_s.underscore
        feature_key = "features.#{name}"
        unless container.key?(feature_key)
          Appfuel.setup_container_dependencies(feature_key, container)
        end

        unless require_feature_disabled?(container, feature_key)
          require "#{container[:features_path]}/#{name}"
        end

        container[:auto_register_classes].each do |klass|
          next unless klass.register?
          container.register(klass.container_class_path, klass)
        end

        return false if initialized?(container, feature_key)

        Appfuel.run_initializers(feature_key, container)
        true
      end

      private
      def require_feature_disabled?(container, feature_key)
        disable_key = "#{feature_key}.disable_require"
        container.key?(disable_key) && container[disable_key] == true
      end

      def initialized?(container, feature_key)
        init_key = "#{feature_key}.initialized"
        container.key?(init_key) && container[init_key] == true
      end
    end
  end
end
