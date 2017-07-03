module Appfuel
  module WebApi
    class Repository < Appfuel::Repository::Base
      class << self
        def container_class_type
          "#{super}.web_api"
        end
      end

      attr_reader :response_handler

      def create(entity, exclude = [])
=begin
        data = to_storage(entity, exclude: ['id'])
        results = []
        data.each do |api_class_key, mapped|
          api_model = api_class(api_class_key)
          results << api_model.create(mapped)
        end

        build(name: entity.domain_name, storage: db_results, type: :web_api)
=end
      end

      def storage_class(domain_name)
        mapper.storage_class(:web_api, domain_name)
      end

      def to_entity(domain_name, storage)
        super(domain_name, :web_api, storage)
      end

      private

      def raise_error(err, message)
        error = RuntimeError.new(message)
        error.set_backtrace(err.backtrace)
        raise error
      end

      def validate_entity_id(entity)
        if entity.id == Types::Undefined
          fail("entity id is #{entity.id}")
        end
      end
    end
  end
end
