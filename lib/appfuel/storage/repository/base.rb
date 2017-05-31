module Appfuel
  module Repository
    # The generic repository behavior. This represents repo behavior that is
    # agnostic to any storage system. The following is a definition of this
    # patter by Martin Fowler:
    #
    #   "The repository mediates between the domain and data mapping
    #    layers using a collection-like interface for accessing domain
    #    objects."
    #
    #    "Conceptually, a Repository encapsulates the set of objects persisted
    #     in a data store and the operations performed over them, providing a
    #     more object-oriented view of the persistence layer."
    #
    #    https://martinfowler.com/eaaCatalog/repository.html
    #
    # While we are not a full repository pattern, we are evolving into it.
    # All repositories have access to the application container. They register
    # themselves into the container, as well as handling the cache from the
    # container.
    class Base
      include Appfuel::Application::AppContainer

      class << self
        attr_writer :mapper

        # Used when the concrete class is being registered, to construct
        # the container key as a path.
        #
        # @example features.membership.repositories.user
        # @example global.repositories.user
        # @example <feature|global>.<container_class_type>.<class|container_key>
        #
        # @return [String]
        def container_class_type
          'repositories'
        end

        # Stage the concrete class that is inheriting this for registration.
        # The reason we have to stage the registration is to give the code
        # enough time to mixin the AppContainer functionality needed for
        # registration. Therefore registration is defered until feature
        # initialization.
        #
        # @param klass [Class] the class inheriting this
        # @return nil
        def inherited(klass)
          stage_class_for_registration(klass)
          nil
        end

        # Mapper holds specific knowledge of storage to domain mappings
        #
        # @return [Mapper]
        def mapper
          @mapper ||= create_mapper
        end

        # Factory method to create a mapper. Each concrete Repository will
        # override this.
        #
        # @param maps [Hash] the domain to storage mappings
        # @return [Mapper]
        def create_mapper(maps = nil)
          Mapper.new(container_root_name, maps)
        end

        # A cache of already resolved domain objects
        #
        # @return [Hash]
        def cache
          app_container[:repository_cache]
        end
      end


      def mapper
        self.class.mapper
      end

      def execute_query_method(query_method, criteria, settings)
        unless respond_to?(query_method)
          fail "Could not excute method #{query_method}"
        end

        public_send(query_method, criteria, settings)
      end

      def query_setup(criteria, settings)
        query_method = "#{criteria.domain_basename}_query"
        execute_query_method(query_method, criteria, settings)
      end

      def query(criteria, settings = {})
        criteria = build_search_criteria(criteria)
        settings = create_settings(settings)

        if settings.manual_query?
          query_method = settings.manual_query
          return execute_query_method(query_method, criteria, settings)
        end

        begin
          result = query_setup(criteria, settings)
          apply_query_conditions(criteria, result, settings)
          resolve_domains(criteria, results, settings)
        rescue => e
          msg = "query failed for #{criteria.domain_name}: " +
                "#{e.class} #{e.message}"
          error = RuntimeError.new(msg)
          error.set_backtrace(e.backtrace)
          raise error
        end
      end

      def apply_query_condition(_result, _criteria, _settings)
        fail "apply_query_condition must be extended by a concrete repo"
      end

      def resolve_domains(_result, _criteria, _settings)
        fail "resolve_domains must be extended by a concrete repo"
      end

      def build_search_criteria(criteria)
        return criteria if search_criteria?(criteria)
        return search_parser.parse(criteria) if criteria.is_a?(String)
        unless criteria.is_a?(Hash)
          fail "criteria must be a String, Hash, or " +
               "Appfuel::Domain::SearchCriteria"
        end
        SearchCriteria.build(criteria)
      end

      def search_criteria?(criteria)
        criteria.instance_of(Appfuel::Domain::SearchCriteria)
      end

      def exists?(criteria)
        expr = criteria.fiilters
        mapper.exists?(expr)
      end

      def to_storage(entity, exclude = [])
        mapper.to_storage(entity, exclude)
      end

      def to_entity(domain_name, storage)
        key  = qualify_container_key(domain_name, "domains")
        hash = mapper.to_entity_hash(domain_name, storage)
        app_container[key].new(hash)
      end

      def build(type:, name:, storage:, **inputs)
        builder = find_entity_builder(type: type, domain_name: name)
        builder.call(storage, inputs)
      end

      # features.membership.presenters.hash.user
      # global.presenters.user
      #
      # key => db_model
      # key => db_model
      def find_entity_builder(domain_name:, type:)
        key = qualify_container_key(domain_name, "domain_builders.#{type}")

        container = app_container
        unless container.key?(key)
          return ->(data, inputs = {}) {
            build_default_entity(domain_name: domain_name, storage: data)
          }
        end

        container[key]
      end

      def build_default_entity(domain_name:, storage:)
        storage = [storage] unless storage.is_a?(Array)

        storage_attrs = {}
        storage.each do |model|
          storage_attrs.merge!(mapper.model_attributes(model))
        end

        hash = mapper.to_entity_hash(domain_name, storage_attrs)
        key  = qualify_container_key(domain_name, "domains")
        app_container[key].new(hash)
      end
    end
  end
end
