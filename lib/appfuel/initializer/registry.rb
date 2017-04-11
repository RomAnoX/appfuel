module Appfuel
  module Initializer
    # The registry builds and stores all initializers. An initializer is a
    # block of code that allows you to execute any setup or initialize
    # dependencies and add them to the application dependency injection
    # container.
    #
    module Registry

      # @return [Array]
      def initializers
        @initializers ||= []
      end

      # @raise [RuntimeError] when no block is given
      #
      # @param name [Symbol, String]
      # @return [lamda]
      def initializer(name, priority: 100, &blk)
        fail "view models must be added with a block" unless block_given?

        name = name.to_s.to_sym
        fail "initializer name can not be empty" if name.empty?
        @initializers << {name: name, priority: priority, runner: blk}
      end

    end
  end
end
