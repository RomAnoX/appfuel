module Appfuel
  module Initialize
    module Setup
      # 1) create a dry container namespace using the app name
      #   a) if no name is given parse the root module,
      #      decoded into lowercase underscore and use that as the name
      #
      # 2) assign the root module & path into that namespace
      #    note: all di assignments will be made with this key, we should
      #    propably cache the app_name and wrap DI access
      #
      # 3) resolve configuration data into a hash and assign it to
      #    the di container with namespace <app_name>.config
      #    a) check for method <config_definition> on the root module
      #       use that definition to populate the config
      #     b) when no definition exists look for config_data method
      #     c) when no config data use an empty hash
      #
      # 4) run initializers. fire off method load_initializers on root
      #   module. This will give the library to do a require for the
      #   correct order of initializers.
      #
      #   Initializer Dsl
      #     1) add initializer block to initializer registry
      #     2) initializer stack is a FIFO stack
      #     3) order is controlled my a main initializer.rb file that is required when
      #        the hook is fired
      #     4) an initializer accepts a container
      def setup_appfuel(params = {})
        root = params.fetch(:root) {
          fail "A root module (:root) is required to setup Appfuel"
        }

        container     = Appfuel.container
        app_name      = handle_app_name(root, params, container)
        app_container = build_app_container(root)

        container.register(app_name, app_container)

        root.load_initializers

        app_container
      end

      # Determine the app name for input params or the parsing the root
      # module if no params are specified. This also handles assigning
      # the default app name so that you don't have give Appfuel the
      # name everytime you want to deal with the container
      #
      # @param root [Module] The root module of the application
      # @param params [Hash] input params from setup
      # @option app_name [String] optional
      # @option default_app [Bool] force the assignment of default name
      #
      # @return [String]
      def handle_app_name(root, params, container)
        app_name  = params.fetch(:app_name) { root.to_s.underscore }
        if params[:default_app] == true || !Appfuel.default_app?
          container.register(:default_app_name, app_name)
        end

        app_name.to_s
      end

      def build_app_container(root, container = Dry::Container.new)
        container.register(:root, root)
        container.register(:initializers, ThreadSafe::Array.new)
        container.register(:config_definition, root.configuration_definition)
        container
      end

      def bootstrap_appfuel(overrides: {}, env: ENV)

      end
    end
  end
end
