module Appfuel
  module Repository
    class Base
      extend Appfuel::Application::ContainerKey
      extend Appfuel::Application::ContainerClassRegistration

      class << self
        attr_writer :registry
        def inherited(klass)
          register_container_class(klass)
        end

        def registry
          @registry ||= registry_from_app_container
        end

        def registry_from_app_container
          container = Appfuel.app_container(container_root_name)
          container[:repository_registry]
        end
      end
    end
  end
end
