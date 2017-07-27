module Appfuel
  module Dynamodb
    class Repository < Appfuel::Repository::Base
      class << self
        def container_class_type
          "#{super}.dynamodb"
        end
      end

      def storage_class(domain_name)
        mapper.storage_class('dynamodb', domain_name)
      end

      def to_entity(domain_name, storage)
        super(domain_name, 'dynamodb', storage)
      end


      def to_storage(domain, opts = {})
        super(domain, 'dynamodb', opts)
      end
    end
  end
end
