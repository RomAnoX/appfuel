module Appfuel
  module AwsDynamodb
    class Repository < Appfuel::Repository::Base
      class << self
        def container_class_type
          "#{super}.aws.dynamo_db"
        end
      end
    end
  end
end
