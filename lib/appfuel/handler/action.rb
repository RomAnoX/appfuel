module Appfuel
  module Handler
    class Action < Base
      class << self
        def inherited(klass)
          container = Appfuel.app_container(klass.root_name)
          container.register(klass.qualified_handler_key, klass)
        end

        def handler_key
          "actions.#{super}"
        end
      end
    end
  end
end
