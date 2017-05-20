module Appfuel
  module Application
    module ContainerClassRegistration
      # All handlers are automatically registered into the application
      # container which allows them to easily be retrieved for execution.
      # The ContainerKey mixin handles converting ruby class namespaces to
      # container key, so we simply need to obtain the qualified namespace
      # key for this class extending this, that does not belong to appfuel.
      #
      # types of classes:
      #   repositories
      #   db
      #   domains
      #
      #   features.repositories.key
      # @param klass [Class] the handler class that is inheriting this
      # @return [Boolean]
      def stage_class_for_registration(klass)
        if !klass.respond_to?(:register_class?) || !klass.register_class?
          return false
        end

        unless klass.respond_to?(:container_root_name)
          fail "#{klass} must implement :container_root_name"
        end
        root = klass.container_root_name
        return false if root == 'appfuel'

        container = Appfuel.app_container(klass.container_root_name)
        container[:auto_register_classes] << klass
      end

      def disable_class_registration
        @is_class_registration = false
      end

      def enable_class_registration
        @is_class_registration = true
      end

      def register_class?
        @is_class_registration ||= true
      end

    end
  end
end
