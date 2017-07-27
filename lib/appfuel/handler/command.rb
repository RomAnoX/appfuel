module Appfuel
  module Handler
    class Command < Base
      class << self
        def container_class_type
          'commands'
        end
      end
    end
  end
end
