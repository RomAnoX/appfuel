module Appfuel
  module Feature
    class ActionLoader
      def call(request, container)
        namespace = request.namespace
        unless container.key?(namespace)
          fail "[ActionLoader] Could not load action at #{namespace}"
        end
        container[namespace]
      end
    end
  end
end
