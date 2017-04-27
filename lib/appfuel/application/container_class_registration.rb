module Appfuel
  module Application
    module ContainerClassRegistration
      # All handlers are automatically registered into the application
      # container which allows them to easily be retrieved for execution.
      # The ContainerKey mixin handles converting ruby class namespaces to
      # container key, so we simply need to obtain the qualified namespace
      # key for this class extending this, that does not belong to appfuel.
      #
      # @param klass [Class] the handler class that is inheriting this
      # @return [Boolean]
      def register_container_class(klass)
        root = klass.container_root_name
        return false if root == 'appfuel'

        container = Appfuel.app_container(root)
        container.register(klass.container_qualified_key, klass)
        true
      end
    end
  end
end
