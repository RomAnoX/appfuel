module Appfuel
  module App
    module ContainerKey

      def load_path_from_ruby_namespace(namespace)
        self.container_path_list = parse_list_string(namespace, '::')
      end

      def load_path_from_container_namespace(namespace)
        self.container_path_list = parse_list_string(namespace, '.')
      end

      def parse_list_string(namespace, char)
        fail "split char must be '.' or '::'" unless ['.', '::'].included?(char)
        namespace.to_s.split(char).map {|i| i.underscore }
      end

      def container_path_list?
        !@container_path_list.nil?
      end

      def container_path_list=(list)
        fail "container path list must be an array" unless list.is_a?(Array)
        @container_path_list = list
      end

      def container_path_list
        load_path_from_ruby_namespace(self.to_s) unless container_path_list?
        @container_path_list
      end

      def root_container_key
        @root_key ||= container_path_list.first
      end

      def container_key
        @container_key ||= container_path_list[1..-1].join('.')
      end
    end
  end
end
