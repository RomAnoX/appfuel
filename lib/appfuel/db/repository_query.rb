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
        unless respond_to?(query_method)
          fail "Could not execute method #{query_method}"
        end

        return public_send(query_method, criteria)
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
        unless respond_to?(query_method)
          fail "Could not execute domain query method #{query_method}"
        end

        return public_send(query_method, criteria)
      end

      # Handles the treatment of the relation when the recordset is empty
      # based on the criteria.
      #
      # @param criteria [Appfuel::Criteria]
      # @return [Appfuel::Error, Appfuel::Domain::EntityNotFound, nil]
      def handle_empty_relation(criteria, _relation)
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

      def query(criteria)
        return execute_criteria(criteria) if criteria.exec?

        begin
          relation = query_relation(criteria)
          relation = if criteria.all?
                      apply_query_all(criteria, relation)
                     else
                      apply_query_conditions(criteria, relation)
                     end

          if relation.blank?
            result = handle_empty_relation(criteria, relation)
            return result if result
          end

          result = build_collection(criteria, relation)
          result = result.first if criteria.single?

          result
        rescue => e
          msg = "query failed for #{criteria.domain}: #{e.class} #{e.message}"
          err = RuntimeError.new(msg)
          err.set_backtrace(e.backtrace)
          raise err
        end
      end

      def build_relation(criteria)
        if criteria.all?
          relation = repo_mapper.db_class(criteria.domain).all
        else
          relation = repo_mapper.where(criteria)
          relation = repo_mapper.order(criteria, relation)
          relation = relation.limit(criteria.limit) if criteria.limit?
          relation
        end
      end

      def build_collection(criteria, relation)
        collection = EntityCollection.new(criteria.domain_name)
        pager      = criteria.pager
        relation   = relation.page(pager.page).per(pager.per_page)

        collection.entity_loader = entity_loader(criteria.domain, relation)
        collection
      end

      def entity_loader(domain_key, relation)
        -> {
          data = {
            total_pages:  relation.total_pages,
            current_page: relation.current_page,
            total_count:  relation.total_count,
            limit_value:  relation.limit_value,
            page_size:    relation.size,
            items: []
          }
          relation.each do |db_item|
            data[:items] << repo_mapper.to_entity(domain_key, db_item)
          end
          data
        }
      end

      def build_entity(name, db_model, mapper)
        if respond_to?("build_#{name}")
          send("build_#{name}", db_model, mapper)
        else
          mapper.to_entity(name, db_model)
        end
      end

      def entity_class?(entity_key, object)
        object == mapper.entity_class(entity_key)
      end
    end
  end
end
