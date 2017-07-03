module Appfuel
  module AwsDynamodb
    class Repository < Appfuel::Repository::Base
      class << self
        def container_class_type
          "#{super}.aws.dynamodb"
        end
      end
    end
  end
end
