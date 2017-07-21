module Appfuel
  module AwsDynamodb
    class Repository < Appfuel::Repository::Base
      class << self
        def container_class_type
          "#{super}.aws.dynamodb"
        end
      end

      def storage_class(domain_name)
        mapper.storage_class('aws.dynamodb', domain_name)
      end

      def to_entity(domain_name, storage)
        super(domain_name, 'aws.dynamodb', storage)
      end
    end
  end
end
