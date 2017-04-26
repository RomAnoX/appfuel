module Appfuel
  module Db
    class Repository
      include Mapper
      include RepositoryQuery

      class << self
        def inherited(klass)

        end
      end

      attr_reader :response_handler


      def build(domain_name, db_model, inputs = {})
        builder = create_entity_builder(domain_name)
        builder.call(db_model, inputs)
      end

      # feature key need to be implementd
      #
      #
      def create_entity_builder(domain_name)

      end

      private
      def raise_error(err, message)
        error = RuntimeError.new(message)
        error.set_backtrace(err.backtrace)
        raise error
      end

      def validatate_entity_id(entity)
        if entity.id == Types::Undefined
          fail "[#{entity.domain_name}] entity id is has not been set"
        end
      end
    end
  end
end
