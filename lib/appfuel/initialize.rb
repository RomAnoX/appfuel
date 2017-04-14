require_relative 'initialize/setup'
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

      def handle_initializers(app_name, container, params)
        exclude = params[:exclude] || []

        env    = container[:env]
        config = container[:config]

        container[:initializers].each do |init|
          next if !init.env_allowed?(env) || exclude.include?(init.name)

          begin
            init.call(config, container)
          rescue => e
            msg = "[Appfuel:#{app_name}] Initialization FAILURE " + e.message
            error = RuntimeError.new(msg)
            error.set_backtrac(e.backtrace)
            raise error
          end
        end
        container
      end

      def run(params = {})
        app_name  = params.fetch(:app_name) { Appfuel.default_app_name }
        container = Appfuel.app_container(app_name)
        handle_configuration(container, params)
        handle_intializers(app_name, container, params)

        container
      end
    end
  end
end
