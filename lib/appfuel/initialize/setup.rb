module Appfuel
  module Initialize
    module Setup
      # Initialize Appfuel by creating an application container for the
      # app represented by the root module passed in. The app container is
      # a dependency injection container that is used thought the app.
      #
      # @raises ArgumentError when root module does not exist
      #
      # @param params [Hash]
      # @option root [Module] root module of the application
      # @option app_name [String, Symbol] key to store container in appfuel
      #
      # @return [Dry::Container]
      def setup_appfuel(params = {})
        root = params.fetch(:root) {
          fail ArgumentError, "Root module (:root) is required to setup Appfuel"
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

      # Initializes the application container with three items:
      #
      # 1) the root module where all features are contained
      # 2) an empty intializer array
      # 3) the applications configuration definition which is used to
      #    build out the config hash
      #
      # @param root [Module] the root module of the application
      # @param container [Dry::Container] dependency injection container
      # @return [Dry::Container]
      def build_app_container(root, container = Dry::Container.new)
        container.register(:root, root)
        container.register(:root_path, root.root_path)
        container.register(:initializers, ThreadSafe::Array.new)
        if root.respond_to?(:configuration_definition)
          container.register(:config_definition, root.configuration_definition)
        end
        container
      end

      def bootstrap_appfuel(overrides: {}, env: ENV)

      end
    end
  end
end
