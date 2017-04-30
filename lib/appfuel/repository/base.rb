module Appfuel
  module Repository
    class Base
      extend Appfuel::Application::ContainerKey
      extend Appfuel::Application::ContainerClassRegistration

      class << self
        attr_writer :mapper
        def inherited(klass)
          register_container_class(klass)
        end

        def mapper
          @mapper ||= create_mapper
        end

        def create_mapper(maps = nil)
          Mapper.new(maps)
        end
      end
    end
  end
end
