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
      def initializer(name, priority: nil, &blk)
        fail "view models must be added with a block" unless block_given?

        base = build_initializer
        name = name.to_s.to_sym
        fail "initializer name can not be empty" if name.empty?
        runner = ->(container) { base.instance_exe(container, &blk) }
        @initializer << {name: name, runner: runner}
      end

      # This will be the class used to call `instance_exec` for the
      # the initializer block
      #
      # @return Appfuel::Initializer::Base
      def initializer_class
        Base
      end


      # Building the initializer class
      #
      # @return Appfuel::ViewModel::Base
      def build_initializer
        view_model_class.new
      end
    end
  end
end
