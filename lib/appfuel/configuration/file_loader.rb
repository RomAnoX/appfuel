module Appfuel
  module Configuration
    # Handle loading files and parsing them correctly based on their type.
    # The file loader used for loading configuration data into a definition
    module FileLoader

      # @param path [String]
      # @return [Hash]
      def parse_json(path)
        file = File.read(path)
        JSON.parse(file)
      end

      # @param path [String]
      # @return [Hash]
      def parse_yaml(path)
        YAML.load_file(path)
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
          ext = File.extname(path).strip.downcase[1..-1]
          parse_method = "parse_#{ext}"
          unless respond_to?(parse_method)
            fail "extension (#{ext}), for (#{key}: #{path}) is not valid, " +
                 "only yaml and json are supported"
          end

          return public_send(parse_method, path) if File.exists?(path)
        end

        list = paths.join(',')
        fail "none of :#{key} config files exist at (#{list})"
      end
    end
  end
end
