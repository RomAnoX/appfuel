module Appfuel
  module Initialize
    class Initializer
      attr_reader :name, :envs, :code

      def initialize(name, env = [], &block)
        @name = name.to_s
        @envs = []

        env = [env] if env.is_a?(String) || env.is_a?(Symbol)
        env = []    if env.nil?

        unless env.is_a?(Array)
          fail ArgumentError, "environments must be a string, symbol or array"
        end
        env.each {|item| add_env(item) }

        fail ArgumentError, "initializer requires a block" unless block_given?
        @code = block
      end

      def env_allowed?(env)
        return true if envs.empty?

        envs.include?(env.to_s.downcase)
      end

      def add_env(name)
        name = name.to_s.downcase
        fail "env already exists" if envs.include?(name)
        envs << name.to_s.downcase
      end

      def call(config, container)
        code.call(config, container)
      end
    end
  end
end
