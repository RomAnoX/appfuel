module Appfuel
  # Builds a list of global and feature commands to be resolved. Feature commands
  # are searched in the feature module Commands module and global command are
  # searched in the root module Commands module. The declarations are kept in a
  # hash where the key is snaked case encoding of the class name of the command
  # and the value is an alias used to assign to a results container.
  module CommandDependency
    module ClassMethods
      def command_dependencies
        @command_dependencies ||= {
          global: {},
          feature: {},
        }
      end

      def resolve_commands(results = Dry::Container.new)
        command_dependencies[:feature].each do |name, result_key|
          key  = result_key || name
          results.register(key, resolve_feature_command(name))
        end

        command_dependencies[:global].each do |name, result_key|
          key  = result_key || name
          results.register(key, resolve_global_command(name))
        end
        results
      end

      def resolve_feature_command(name)
        name = name.to_s.camelize
        mod  = feature_module
        fail "feature module must be a Module" unless mod.is_a?(Module)
        fail "Commands not found in #{mod}" unless mod.const_defined?(:Commands)
        mod = mod.const_get(:Commands)

        fail "command #{name} not found in #{mod}" if !mod.const_defined?(name)

        mod.const_get(name)
      end

      def resolve_global_command(name)
        name = name.to_s.camelize
        mod  = root_module
        fail "root module must be a Module" unless mod.is_a?(Module)
        fail "Commands not found in #{mod}" unless mod.const_defined?(:Commands)
        mod = mod.const_get(:Commands)

        unless mod.const_defined?(name)
          fail "command #{name} not found in #{mod}"
        end

        mod.const_get(name)
      end

      # Dsl used to declare a command that is located in the Commands
      # module of the feature module
      #
      # @param name Symbol  snakecase name of the command
      # @param opts Hash
      #   as:   custom name for this dependency in action container
      def command(name, opts = {})
        location = opts[:global] == true ? :global : :feature
        command_dependencies[location][name.to_sym] = opts[:as]
      end

    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
