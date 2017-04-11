module Appfuel
  module Initialize
    class Initializer
      attr_reader :name, :envs, :code

      def initialize(name, envs = [], &block)
        @name = name.to_s
        envs = [envs] if envs.is_a?(String) || envs.is_a?(Symbol)
        unless envs.is_a?(Array)
          fail ArgumentError, "environments must be a string, symbol or array"
        end
        @envs = envs
        fail ArgumentError, "initializer requires a block" unless block_given?

        @code = block
      end

    end
  end
end
