module Appfuel
  module ApplicationRoot
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
      app_container       = params[:app_container] || Dry::Container.new
      framework_container = Appfuel.framework_container

      app_container = build_app_container(params, app_container)
      app_name = handle_app_name(params, app_container, framework_container)

      app_container.register(:app_name, app_name)
      framework_container.register(app_name, app_container)

      if params.key?(:on_after_setup)
        handle_after_setup(params[:on_after_setup], app_container)
      end

      app_container
    end

    def handle_after_setup(hook, container)
      unless hook.respond_to?(:call)
        fail ArgumentError, "After setup hook (:after_setup) must " +
          "implement :call, which takes the di container as its only arg"
      end
      hook.call(container)
    end

    # The application name is determined by the root module. We use the
    # lower case underscored version of the root module name
    #
    # @param root [Module] The root module of the application
    # @param params [Hash] input params from setup
    # @option app_name [String] optional
    # @option default_app [Bool] force the assignment of default name
    #
    # @return [String]
    def handle_app_name(params, app_container, framework_container)
      app_name = app_container[:root].to_s.underscore

      if params[:default_app] == true || !Appfuel.default_app?
        framework_container.register(:default_app_name, app_name)
      end

      app_name
    end

    # Initializes the application container with:
    #
    # Application Container
    #   root: This is the root module that holds the namespaces for all
    #         features, actions, commands etc. This is required.
    #
    #   root_path: This is the root path of app where the source code
    #              lives. We use this to autoload this features. This
    #              is still under design so it might not stay.
    #
    #   config_definition: This is the definition object that we use to
    #                      build out the configuration hash. This is optional
    #
    #   initializers: This is an array that hold all the initializers to be
    #                 run. This builder will handle creating the array. It is
    #                 populated via appfuel dsl Appfuel::Initialize#define
    #
    #   global.validators: This is a hash that holds all global validators.
    #                      this builder will handle creating the hash. It is
    #                      populated via appfuel dsl
    #                      Appfuel::Validator#global_validator
    #
    #   global.domain_builders:
    #   global.presenters
    #
    # @param root [Module] the root module of the application
    # @param container [Dry::Container] dependency injection container
    # @return [Dry::Container]
    def build_app_container(params, container = Dry::Container.new)
      root = params.fetch(:root) {
        fail ArgumentError, "Root module (:root) is required"
      }

      root_path = params.fetch(:root_path) {
        fail ArgumentError, "Root path (:root_path) is required"
      }

      feature_initializer = params.fetch(:feature_initializer) {
        Feature::Initializer.new
      }

      action_loader = params.fetch(:action_loader) {
        Feature::ActionLoader.new
      }

      root_name = root.to_s.underscore
      container.register(:root, root)
      container.register(:root_name, root_name)
      container.register(:root_path, root_path)
      container.register(:features_path, "#{root_name}/features")
      container.register(:feature_initializer, feature_initializer)
      container.register(:action_loader, action_loader)

      if params.key?(:config_definition)
        container.register(:config_definition, params[:config_definition])
      end

      Appfuel.setup_container_dependencies('global', container)

      container
    end

    def bootstrap(overrides: {}, env: ENV)
      Initialize.run(overrides: overrides, env: env)
    end

    def call(route, inputs = {})
      container = Appfuel.app_container
      request   = Request.new(route, inputs)

      container[:feature_initializer].call(request.feature, container)
      action = container[:action_loader].call(request, container)
      ap 'going to dispatch action:'
      ap action
      action.run(inputs)
    end
  end
end
