module Appfuel
  module Configuration
    module Populate
      # This converts a definition into a hash of configuation values. It does
      # this using the following steps
      #
      # 1. load config data from a yaml or json file if a file is defined
      # 2. populate all children
      # 3. merge defaults into config data that has been given or resolved
      #    from the config file
      # 4. merge override data into the results from step 3
      # 5. run validation and assign clean data to config with the key
      #
      # @throws RuntimeError when validation fails
      # @param data Hash holds overrides and config source data
      # @return Hash
      def populate(data = {})
        overrides = data[:overrides] || {}
        config    = data[:config] || {key => {}}

        if overrides.key?(:config_file) && !overrides[:config_file].nil?
          file overrides[:config_file]
        end

        config = load_file(self) if file?
        config[key] ||= {}

        config[key] = defaults.deep_merge(config[key])
        config[key] = config[key].deep_merge(overrides[key] || {})

        populate_children(children, config[key]) unless children.empty?

        config[key] = handle_validation(config[key])
        config
      end

      protected

      def populate_children(child_hash, data)
        child_hash.each do |(def_key, definition)|
          data[def_key] ||= {}
          data[def_key] = load_file(definition) if definition.file?

          data[def_key] = definition.defaults.deep_merge(data[def_key])

          unless definition.children.empty?
            populate_children(definition.children, data[def_key])
          end

          data[def_key] = definition.handle_validation(data[def_key])
       end
      end

      def handle_validation(data)
        return data unless validator?

        result = validator.call(data)
        if result.failure?
          msg = validation_error_message(result.errors(full: true))
          fail msg
        end
        result.to_h
      end

      def validation_error_message(errors)
        msg = ''
        errors.each do |(error_key, values)|
          if values.is_a?(Hash)
            values = values.values.uniqu
          end
          msg << "[#{key}] #{error_key}: #{values.join("\n")}\n"
        end
        msg
      end
    end
  end
end
