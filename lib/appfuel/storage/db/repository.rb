module Appfuel
  module Db
    class Repository < Appfuel::Repository::Base
      class << self
        def container_class_type
          "#{super}.db"
        end

        def create_mapper(maps = nil)
          Mapper.new(container_root_name, maps)
        end
      end

      attr_reader :response_handler

      def create(entity, exclude = [])
        data = to_storage(entity, exclude: ['id'])
        db_results = []
        data.each do |db_class_key, mapped|
          db_model  = db_class(db_class_key)
          db_results << db_model.create(mapped)
        end

        build(name: entity.domain_name, storage: db_results, type: :db)
      end

      def db_class(key)
        app_container[key]
      end

      # Handles the treatment of the relation when the recordset is empty
      # based on the criteria.
      #
      # @param criteria [SpCore::Criteria]
      # @return [SpCore::Error, SpCore::Domain::EntityNotFound, nil]
      def handle_empty_relation(criteria, relation)
        return nil unless relation.blank?

        if criteria.error_on_empty_dataset?
          return error(criteria.domain => ["#{criteria.domain} not found"])
        end

        if criteria.single?
          return create_entity_not_found(criteria)
        end
      end

      # Null object used when you can not find a given entity
      #
      # @param criteria [SpCore::Criteria]
      # @return SpCore::Domain::EntityNotFound
      def create_entity_not_found(criteria)
        Appfuel::Domain::EntityNotFound.new(entity_name: criteria.domain_name)
      end

      # Apply where, order and limit clauses to the relation based on the
      # criteria.
      #
      # @param criteria [SpCore::Criteria]
      # @param relation [mixed]
      # @return relation
      def apply_query_conditions(criteria, relation)
        relation = where(criteria, relation)
        relation = order(criteria, relation)
        relation = limit(criteria, relation)
        relation
      end

      # Determines which query conditions to apply to the relation
      #
      # @param criteria [SpCore::Criteria]
      # @param relation
      # @return relation
      def handle_query_conditions(criteria, relation, settings)
        if settings.all?
          return order(criteria, relation.all)
        end

        apply_query_conditions(criteria, relation)
      end

      def where(criteria, relation)

      end

      def where_conditions(criteria)

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

