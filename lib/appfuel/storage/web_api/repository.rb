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

      # when key has no . assume the feature of the repository
      #
      #
      def api_class(key)
        unless key.include?('.')
          key = "features.#{self.class.container_feature_name}.web_api.#{key}"
        end
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
      def apply_query_conditions(criteria, relation, _settings)

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

        apply_query_conditions(criteria, relation, settings)
      end

      def handle_empty_relation(criteria, relation, settings)
        unless relation.respond_to?(:blank?)
          fail "The database relation invalid, does not implement :blank?"
        end

        return nil unless relation.blank?

        if criteria.error_on_empty_dataset?
          return domain_not_found_error(criteria)
        end

        if criteria.single?
          return domain_not_found(criteria)
        end
      end

      # 1) lookup query id in cache
      #   if found build collection from cached query ids
      #
      # 2) query id not found in cache
      #   a) assign query id from criteria
      #   b) find the domain builder for that criteria
      #   c) loop through each item in the database relation
      #   d) build an domain from each record in the relation
      #   e) create cache id from the domain
      #   f) record cache id into a list that represents query
      #   g) assign domain into the cache with its cache id
      #       id is in the cache the its updated *represents a miss
      #   h) assign the query list into the cache with its query id
      #
      def build_domains(criteria, relation, settings)
        result  = handle_empty_relation(criteria, relation, settings)
        return result if result


        if settings.single?
          method   = settings.first? ? :first : :last
          db_model = relation.send(method)
          builder  = domain_builder(criteria.domain_name)
          domain   = builder.call(db_model, criteria)
          ap domain
        end

      end

      def domain_builder(domain_name)
        key = qualify_container_key(domain_name, 'domain_builders.db')
        app_container[key]
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
