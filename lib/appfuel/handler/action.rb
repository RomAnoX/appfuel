module Appfuel
  module Handler
    class Action < Base
      class << self
        def handler_key
          "actions.#{super}"
        end
      end
    end
  end
end
