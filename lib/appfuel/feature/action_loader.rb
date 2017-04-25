module Appfuel
  module Feature
    # Loads an action from the container using its fully qualified namespace.
    # This class has been abstracted out because its Appfuel's implementation
    # of loading an action. This action loader is injected into the container
    # during setup which allows the client to use their own if this basic
    # lookup mehtod does not work for them.
    #
    # The idea is that all actions, commands and repositories auto register
    # themselves into the container based on a namespace derived inpart by
    # their own ruby namespace.
    class ActionLoader
      # @raises RuntimeError when key is not found
      # @param namespace [String] fully qualifed container namespace
      # @param container [Dry::Container] application container
      # @return [Appfuel::Handler::Action]
      def call(namespace, container)
        unless container.key?(namespace)
          fail "[ActionLoader] Could not load action at #{namespace}"
        end
        container[namespace]
      end
    end
  end
end
