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
        key   = definition.key

        paths.each do |path|
          ext = file_module.extname(path).strip.downcase[1..-1]
          parse_method = "parse_#{ext}"
          unless respond_to?(parse_method)
            fail "extension (#{ext}), for (#{key}: #{path}) is not valid, " +
                 "only yaml and json are supported"
          end

          return public_send(parse_method, path) if file_module.exists?(path)
        end

        list = paths.join(',')
        fail "none of :#{key} config files exist at (#{list})"
      end
    end
  end
end
