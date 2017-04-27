module Appfuel
  module Application
    # Mixins to allow you to handle application container keys. The application
    # container operates based on certain conventions which we take into account
    # here.
    module ContainerKey
      # Parse the namespace assuming it is a ruby namespace and assign
      # the list to container_path_list
      #
      # @param namespace [String]
      # @return [Array]
      def load_path_from_ruby_namespace(namespace)
        self.container_path = parse_list_string(namespace, '::')
      end

      # Parse the namespace assuming it is a dry container namespace and
      # assign the list to container_path_list
      #
      # @param namespace [String]
      # @return [Array]
      def load_path_from_container_namespace(namespace)
        self.container_path = parse_list_string(namespace, '.')
      end

      # @param namespace [String] encoded string that represents a path
      # @param char [String] character used to split the keys into a list
      # @return [Array] an array of lower case snake cased strings
      def parse_list_string(namespace, char)
        fail "split char must be '.' or '::'" unless ['.', '::'].include?(char)
        namespace.to_s.split(char).map {|i| i.underscore }
      end

      # return [Boolean]
      def container_path?
        !@container_path.nil?
      end

      # @param list [Array] list of container namespace parts including root
      # @return [Array]
      def container_path=(list)
        fail "container path list must be an array" unless list.is_a?(Array)
        @container_path = list
        @container_path.freeze
      end

      # An array representation of the application container namespace, where
      # the root is the name of the application and not part of the namespace
      # and the rest is hierarchical path to features or globals
      #
      # @return [Array]
      def container_path
        load_path_from_ruby_namespace(self.to_s) unless container_path?
        @container_path
      end

      # This is the application name used to identify the application container
      # that is stored in the framework container
      #
      # @return string
      def container_root_name
        @container_root_name ||= container_path.first
      end

      # All root namespace for anything inside features, use this name. It is
      # important to note that to avoid long namespace in ruby features are the
      # name of the module directly below the root.
      #
      # @return [String]
      def container_features_root_name
        @container_features_root_name ||= 'features'
      end

      # The actual name of the feature
      #
      # @return [String]
      def container_feature_name
        container_path[1]
      end

      # The feature name is the second item in the path, that is always prexfix
      # with "features"
      #
      # @return [String]
      def container_feature_key
        @container_feature_key ||= (
          "#{container_features_root_name}.#{container_feature_name}"
        )
      end

      # Container key relative from feature or global, depending on which class
      # this is mixed into
      #
      # @return [String]
      def container_relative_key
         @container_relative_key ||= container_path[2..-1].join('.')
      end

      # This refers to either the global path or the path to a particular
      # feature
      #
      # @return [String]
      def top_container_key
        container_global_path? ? container_global_name : container_feature_key
      end

      # Fully qualified key, meaning you can access the class this was mixed into
      # if you stored it into the container using this key
      #
      # @return [String]
      def container_qualified_key
        @container_qualified_key ||= (
          "#{top_container_key}.#{container_relative_key}"
        )
      end

      # Determines if the container path represents a global glass
      #
      # @return [Boolean]
      def container_global_path?
        container_path[1] == container_global_name
      end

      # @return [String]
      def container_global_name
        @container_global_name ||= 'global'
      end
    end
  end
end
