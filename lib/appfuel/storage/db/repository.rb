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

      # Used when the automated query methods don't suite your use case. It
      # is assumed that the method executed will honor the same interfaces as
      # query does
      #
      # @param criteria [SpCore::Criteria]
      # @return [Dataset]
      def execute_criteria(criteria)
        query_method = "#{criteria.exec}_manual_query"
        validate_query_method(query_method)

        public_send(query_method, criteria)
      end

      # Use the criteria entity's basename as a convention to find a method
      # on the repository that returns the necessary relation (db scope) for
      # which to add conditions that will be used to complete the query.
      #
      #
      # @param criteria [SpCore::Criteria]
      # @return [ActiveRecord::Relation]
      def query_relation(criteria)
        query_method = "#{criteria.domain}_query"
        validate_query_method(query_method)

        public_send(query_method)
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

      # We have an interface for getting all recordsets separately because
      # this is usually done with no filters or limits.
      #
      # @param criteria [SpCore::Criteria]
      # @param relation
      # @return relation
      def apply_query_all(criteria, relation)
        unless criteria.all?
          fail "This interface can only be used when the criteria :all is used"
        end

        order(criteria, relation.all)
      end

      # Determines which query conditions to apply to the relation
      #
      # @param criteria [SpCore::Criteria]
      # @param relation
      # @return relation
      def handle_query_conditions(criteria, relation)
        if criteria.all?
          return apply_query_all(criteria, relation)
        end

        apply_query_conditions(criteria, relation)
      end

      # Factory method to create a pagination result
      #
      # @param data [Hash]
      # @return [SpCore::Pagination::Result]
      def create_pager_result(data)
        Appfuel::Pagination::Result.new(data)
      end

      # Factory method to create a domain entity
      #
      # @param domain_name [String]
      # @return [SpCore::Domain::EntityCollection]
      def create_entity_collection(domain_name)
        Appfuel::Domain::EntityCollection.new(domain_name)
      end

      # Creates a lambda to used with the entity collection
      #
      # @param criteria [SpCore::Criteria]
      # @param relation [Object]
      # @param builder  [Object]
      # @return lambda
      def entity_loader(criteria, relation, builder)
        -> { load_collection(criteria, relation, builder) }
      end

      # A collection is usually loaded within an entity collection via
      # a lambda. It setups up pagination results and builds an entity
      # foreach record in the list
      #
      # @param criteria [SpCore::Criteria]
      # @param relation [Object]
      # @param builder  [Object]
      # @return [Hash]
      def load_collection(criteria, relation, builder)
        data = { items: [] }
        unless criteria.disable_pagination?
          relation = relation.page(criteria.page).per(criteria.per_page)
          data[:pager] = create_pager_result(
            total_pages:  relation.total_pages,
            current_page: relation.current_page,
            total_count:  relation.total_count,
            page_limit:   relation.limit_value,
            page_size:    relation.size
          )
        end

        relation.each do |db_item|
          data[:items] << builder.call(db_item)
        end
        data
      end

      # Create an entity collection and assign the entity loader with
      # the entity builder class.
      #
      # @param criteria [SpCore::Criteria]
      # @param relation relation
      # @return SpCore::Domain::EntityCollection
      def build_criteria_entities(criteria, relation)
        builder = create_entity_builder(criteria.domain_name)
        result  = handle_empty_relation(criteria, relation)
        # when this has a result it means an empty relation has been
        # handled and ready for return otherwise it was a no op
        return result if result

        if criteria.single?
          relation_method = criteria.first? ? :first : :last
          return builder.call(relation.send(relation_method))
        end

        collection = create_entity_collection(criteria.domain_name)
        collection.entity_loader = entity_loader(criteria, relation, builder)
        collection
      end

      # Query will use the database model to build a query based on the
      # given criteria. It supports where, order and limit conditions.
      #
      # @param criteria [SpCore::Criteria]
      # @return [SpCore::Domain::Entity, SpCore::Domain::EntityCollection]
      def query(criteria)
        return execute_criteria(criteria) if criteria.exec?

        begin
          relation = query_relation(criteria)
          relation = handle_query_conditions(criteria, relation)
          build_criteria_entities(criteria, relation)
        rescue => e
          msg = "query failed for #{criteria.domain}: #{e.class} #{e.message}"
          err = RuntimeError.new(msg)
          err.set_backtrace(e.backtrace)
          raise err
        end
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

