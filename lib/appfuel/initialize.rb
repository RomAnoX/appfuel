require_relative 'initialize/initializer'

module Appfuel
  module Initialize
    class << self

      # Dsl used to add an initializer into to the application container. This
      # will add an initializer into the default app unless another name is
      # given.
      #
      # @param name [String] name of the initializer
      # @param envs [String, Symbol, Array] A env,list of envs this can run in
      # @param app_name [String] name of app for this initializer
      def define(name, envs = [], app_name = nil, &block)
        if !name.is_a?(String) && !name.include?('.')
          fail "initializer name must be a string in the in the form of " +
                "([feature|global].initializer_name)"
        end
        top, name = name.split('.')
        top = "features.#{top}" unless top == 'global'
        namespace   = "#{top}.initializers.#{name}"
        container   = Appfuel.app_container(app_name)
        initializer = Initializer.new(name, envs, &block)
        container.register(namespace, initializer)

        initializer
      end

      def runlist(name, list, app_name = nil)
        namespace = "#{name}.initializers.run"
        unless name == 'global'
          namespace = "features.#{namespace}"
        end
        list = [list] unless list.is_a?(Array)
        fail "run list must be [String|Symbol|Array]" unless list.is_a?(Array)

        container = Appfuel.app_container(app_name)
        container.register(namespace, list)
        nil
      end

      # Populate configuration definition that is in the container and
      # add its results to the container. It also adds the environment from
      # the config to the container for easier access.
      #
      # @raises RuntimeError when :env is not in the config
      #
      #
      # @param container [Dry::Container]
      # @param params [Hash]
      # @option overrides [Hash] used to override config values
      # @option env [ENV] used to collect environment variables
      # @return [Dry::Container] that was passed in
      def handle_configuration(container, params = {})
        overrides    = params[:overrides]  || {}
        env          = params[:env]        || ENV
        definition   = container['config_definition']

        config = definition.populate(env: env, overrides: overrides)
        env = config.fetch(:env) { fail "key (:env) is missing from config" }

        container.register(:config, config)
        container.register(:env, env)

        container
      end

      def handle_repository_mapping(container, params = {})
        initializer = container[:repository_initializer]
        initializer.call(container)
      end

      # This will initialize the app by handling configuration and running
      # all the initilizers, which will result in an app container that has
      # registered the config, env, and anything else the initializers
      # decide to add.
      #
      # @param params [Hash]
      # @option app_name [String] name of the app to initialize, (optional)
      # @return [Dry::Container]
      def run(params = {})
        app_name  = params.fetch(:app_name) { Appfuel.default_app_name }
        container = Appfuel.app_container(app_name)
        if container.key?(:initialized) && container[:initialized] == true
          return container
        end

        handle_configuration(container, params)
        handle_repository_mapping(container, params)

        Appfuel.run_initializers('global', container, params[:exclude] || [])

        container.register(:initialized, true)
        container
      end
    end
  end
end
