module Appfuel
  module Db
    class Repository
      extend Appfuel::Application::ContainerKey
      include Mapper
      include RepositoryQuery

      class << self
        def inherited(klass)
          root = klass.container_root_name
          return if root == 'appfuel'

          container = Appfuel.app_container(root)
          container.register(klass.container_qualified_key, klass)
        end
      end

    end
  end
end
