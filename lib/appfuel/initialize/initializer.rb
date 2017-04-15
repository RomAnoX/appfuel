module Appfuel
  module Initialize
    # The client application will declare a series of initializer blocks.
    # Each of these blocks are represented as this class. This allows us
    # to save the block to be later executed along with info about which
    # environments this can run on
    class Initializer
      attr_reader :name, :envs, :code

      # Ensure each environment is stored as a lowercased string, convert
      # the name to a string as save the block to be executed later
      #
      # @raises ArgumentError, when env is not an Array
      # @raises ArgumentError, when block is not given
      #
      # @param name [String, Symbol] name to identify this initializer
      # @param env [String, Symbol, Array] env or list of envs to execute on
      # @param blk [Proc] the code to be excuted
      # @return [Initializer]
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

      # Determines which env this is allowed to execute on. No enironment means
      # it it is allow to execute on all
      #
      # @param env [String, Symbol]
      # @return [Bool]
      def env_allowed?(env)
        return true if envs.empty?

        envs.include?(env.to_s.downcase)
      end

      # @raises RuntimeError, when env already exists
      #
      # @param name [String, Symbol] name of the environment
      # @return [Array]
      def add_env(name)
        name = name.to_s.downcase
        fail "env already exists" if envs.include?(name)
        envs << name.to_s.downcase
      end

      # Delegate to executing the stored code
      #
      # @param config [Hash]
      # @param app_container [Dry::Container]
      # @return nil
      def call(config, container)
        code.call(config, container)
        nil
      end
    end
  end
end
