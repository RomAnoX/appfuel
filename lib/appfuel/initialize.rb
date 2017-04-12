require_relative 'initialize/setup'
require_relative 'initialize/initializer'

module Appfuel
  module Initialize
    class << self
      def define(name, envs = [], &block)
        initializers = Appfuel.resolve(:initializers)
        initializers << Initializer.new(name, envs, &block)
      end

      def run(params = {})
        app_name     = params.fetch(:app_name) { Appfuel.default_app_name }
        container    = Appfuel.app_container(app_name)

        overrides    = params[:overrides]  || {}
        exclude      = params[:exclude]    || []
        env          = params[:env]        || ENV

        initializers = container[:initializers]
        definition   = container[:config_definition]

        config = definition.populate(env: env, overrides: overrides)

        container.register('config', config)
        env = config.fetch(:env) { fail "key (:env) is missing from config" }

        initializers.each do |init|
          next if !init.env_allowed?(env) || exclude.include?(init.name)

          init.call(config, container)
        end
        container
      end
    end
  end
end
