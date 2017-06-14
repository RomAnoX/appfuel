module Appfuel
  module Configuration
    # Handle loading files and parsing them correctly based on their type.
    # The file loader used for loading configuration data into a definition
    module FileLoader
      attr_writer :file_module, :json_module, :yaml_module

      def file_module
        @file_module ||= ::File
      end

      def json_module
        @json_module || ::JSON
      end

      def yaml_module
        @yaml_module ||= YAML
      end

      # @param path [String]
      # @return [Hash]
      def parse_json(path)
        file = file_module.read(path)
        json_module.parse(file)
      end

      # @param path [String]
      # @return [Hash]
      def parse_yaml(path)
        yaml_module.load_file(path)
      end
      alias_method :parse_yml, :parse_yaml

      # Load file will search through a configuration's definition file
      # paths and use the first on that exists. It parse it based on
      # the file type.
      #
      # @raises [RuntimeException] when no files are found
      #
      # @param definition [DefinitionDsl]
      # @return [Hash]
      def load_file(definition)
        paths = definition.file

        paths.each do |path|
          ext = file_module.extname(path).strip.downcase[1..-1]
          parse_method = "parse_#{ext}"
          unless respond_to?(parse_method)
            fail "extension (#{ext}), for (#{definition.key}: #{path}) " +
                 "is not valid, only yaml and json are supported"
          end

          if file_module.exists?(path)
            config = public_send(parse_method, path)
            unless config.is_a?(Hash)
              fail "[config #{parse_method}] config must be a hash"
            end
            config.deep_symbolize_keys!
            return config[definition.key]
          end
        end

        list = paths.join(',')
        fail "none of :#{definition.key} config files exist at (#{list})"
      end
    end
  end
end
