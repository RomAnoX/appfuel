module Appfuel
  module Repository
    class Base
      extend Appfuel::Application::ContainerKey
      extend Appfuel::Application::ContainerClassRegistration

      class << self
        def inherited(klass)
          register_container_class(klass)
        end
      end
    end
  end
end
