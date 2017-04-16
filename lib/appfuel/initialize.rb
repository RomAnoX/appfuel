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
        initializers = Appfuel.resolve('initializers', app_name)
        initializers << Initializer.new(name, envs, &block)
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

      # Run all initializers registered in the app container
      #
      # @param container [Dry::Container] application container
      # @param app_name [String] name of the app for errors
      # @param params [Hash]
      # @option excludes [Array] list of initializers to exclude from running
      # @return [Dry::Container] same container passed in
      def handle_initializers(container, app_name, params = {})
        exclude = params[:exclude] || []
        unless exclude.is_a?(Array)
          fail ArgumentError, ":exclude must be an array"
        end
        exclude.map! {|item| item.to_s}

        env    = container[:env]
        config = container[:config]
        container[:initializers].each do |init|
          if !init.env_allowed?(env) || exclude.include?(init.name)
            next
          end

          begin
            init.call(config, container)
          rescue => e
            msg = "[Appfuel:#{app_name}] Initialization FAILURE - " + e.message
            error = RuntimeError.new(msg)
            error.set_backtrace(e.backtrace)
            raise error
          end
        end
        container
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
        handle_configuration(container, params)
        handle_initializers(container, app_name, params)

        container
      end
    end
  end
end
