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
        self.container_path_list = parse_list_string(namespace, '::')
      end

      # Parse the namespace assuming it is a dry container namespace and
      # assign the list to container_path_list
      #
      # @param namespace [String]
      # @return [Array]
      def load_path_from_container_namespace(namespace)
        self.container_path_list = parse_list_string(namespace, '.')
      end

      # @param namespace [String] encoded string that represents a path
      # @param char [String] character used to split the keys into a list
      # @return [Array] an array of lower case snake cased strings
      def parse_list_string(namespace, char)
        fail "split char must be '.' or '::'" unless ['.', '::'].include?(char)
        namespace.to_s.split(char).map {|i| i.underscore }
      end

      # return [Boolean]
      def container_path_list?
        !@container_path_list.nil?
      end

      # The path can be manually set if needed
      # @param list [Array] list of container namespace parts including root
      # @return [Array]
      def container_path_list=(list)
        fail "container path list must be an array" unless list.is_a?(Array)
        @container_path_list = list
      end

      # An array representation of the application container namespace, where
      # the root is the name of the application and not part of the namespace
      # and the rest is hierarchical path to features or globals
      #
      # @return [Array]
      def container_path_list
        load_path_from_ruby_namespace(self.to_s) unless container_path_list?
        @container_path_list
      end

      # This is the application name used to identify the application container
      # that is stored in the framework container
      #
      # @return string
      def container_root_key
        @container_root_key ||= container_path_list.first
      end

      def features_key
        @container_features_key ||= 'features'
      end

      # The feature name is the second item in the path, that is always prexfix
      # with "features"
      #
      # @return [String]
      def feature_key
        @container_feature_key ||= "features.#{container_path_list[1]}"
      end

      def container_key(type, partial_key)
        key, *parts = partial_key.to_s.split('.')
        key = "features.#{key}" unless key == 'global'
        "#{key}.#{type.to_s}.#{parts.join('.')}"
      end

      # @return [String]
      def global_key
        @container_global_key ||= 'global'
      end
    end
  end
end
