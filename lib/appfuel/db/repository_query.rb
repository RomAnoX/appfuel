module Appfuel
  module Db
    module RepositoryQuery
      # Used when the automated query methods don't suite your use case. It
      # is assumed that the method executed will honor the same interfaces as
      # query does
      #
      # @param criteria [Appfuel::Criteria]
      # @return [Dataset]
      def execute_criteria(criteria)
        query_method = "#{criteria.exec}_query"
        call_query_method(query_method, criteria)
      end

      # Use the criteria entity's basename as a convention to find a method
      # on the repository that returns the necessary relation (db scope) for
      # which to add conditions that will be used to complete the query.
      #
      #
      # @param criteria [Appfuel::Criteria]
      # @return [ActiveRecord::Relation]
      def query_relation(criteria)
        query_method = "#{criteria.domain}_query"
        call_query_method(query_method, criteria)
      end

      # Handles the treatment of the relation when the recordset is empty
      # based on the criteria.
      #
      # @param criteria [Appfuel::Criteria]
      # @return [Appfuel::Error, Appfuel::Domain::EntityNotFound, nil]
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
      # @param criteria [Appfuel::Criteria]
      # @return Appfuel::Domain::EntityNotFound
      def create_entity_not_found(criteria)
        Appfuel::Domain::EntityNotFound.new(entity_name: criteria.domain_name)
      end

      # Apply where, order and limit clauses to the relation based on the
      # criteria.
      #
      # @param criteria [Appfuel::Criteria]
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
      # @param criteria [Appfuel::Criteria]
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
      # @param criteria [Appfuel::Criteria]
      # @param relation
      # @return relation
      def handle_query_conditions(criteria, relation)
        if criteria.all?
          return apply_query_all(criteria, relation)
        end

        apply_query_conditions(criteria, relation)
      end

      # Find the entity builder based on the criteria and
      # return an instance of that class
      #
      # @raise [RuntimeError] when entity build class does not exist
      #
      # @param criteria [SpCore::Criteria]
      # @return a entity builder
      def create_entity_builder(criteria)
        klass = "Builder::Db#{criteria.domain.classify}"
        mod   = find_parent_module(criteria)
        unless mod.const_defined?(klass)
          fail "Entity Builder (#{klass}) not found for #{mod}"
        end

        mod.const_get(klass).new
      end

      def build_entities(criteria, relation)
        builder = create_entity_builder(criteria)
        result  = handle_empty_relation(criteria, relation)
        return result if result
        return builder.call(criteria, relation) if criteria.single?

        collection = create_entity_collection(criteria.domain_name)
        collection.entity_loader = entity_loader(criteria, relation, builder)
        collection
      end

      def query(criteria)
        return execute_criteria(criteria) if criteria.exec?

        begin
          relation = query_relation(criteria)
          relation = handle_query_conditions(criteria, relation)
          build_entitites(criteria, relation)
        rescue => e
          msg = "query failed for #{criteria.domain}: #{e.class} #{e.message}"
          err = RuntimeError.new(msg)
          err.set_backtrace(e.backtrace)
          raise err
        end
      end

      def entity_loader(criteria, relation, builder)
        -> { load_collection(criteria, relation, builder) }
      end


      def load_collection(criteria, relation, builder)
        pager_request = criteria.pager
        relation = relation.page(pager_request.page).per(pager_request.per_page)

        data[:pager] = create_pager_result(
          total_pages:  relation.total_pages,
          current_page: relation.current_page,
          total_count:  relation.total_count,
          limit_value:  relation.limit_value,
          page_size:    relation.size
        )

        relation.each do |db_item|
          data[:items] << builder.call(criteria, db_item)
        end
        data
      end

      def create_pager_result(data)
        Appfuel::Pagination::Result.new(data)
      end

      def create_entity_collection(domain_name)
        Appfuel::Domain::EntityCollection.new(domain_name)
      end

      private

      def call_query_method(method, criteria)
        fail "Could not execute method #{method}" unless respond_to?(method)

        return public_send(method, criteria)
      end

      # Determine if you need the root module, or you need the feature module
      # based on the criteria. Global domain builders would be located at the
      # root module.
      #
      # @param criteria [Appfuel::Criteria]
      # @return [Module]
      def find_parent_module(criteria)
        mod = root_module
        unless criteria.global_domain?
          feature = criteria.feature.classify
          unless root_module.const_defined?(feature)
            fail "Feature (#{feature}) not found for #{mod}"
          end
          mod = root_module.const_get(feature)
        end
        mod
      end
    end
  end
end
