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


      # @return [Mapper]
      def mapper
        self.class.mapper
      end

      # Validate the method exists and call it with the criteria and
      # settings objects
      #
      # @params query_method [String] method to call
      # @params criteria [SearchCriteria]
      # @params settings [Settings]
      # @return DomainCollection
      def execute_query_method(query_method, criteria, settings)
        unless respond_to?(query_method)
          fail "Could not execute query method (#{query_method})"
        end

        public_send(query_method, criteria, settings)
      end

      # The first method called in the query life cycle. It setups up the
      # query method used to return a query relation for the next method
      # in the life cycle. This query method will return a query relation
      # produced by the concrete repo for that domain. The relation is specific
      # to the type of repo, a db repo will return an ActiveRecordRelation for
      # example.
      #
      # @param criteria [SearchCriteria]
      # @param settings [Settings]
      # @return [Object] A query relation
      def query_setup(criteria, settings)
        query_method = "#{criteria.domain_basename}_query"
        execute_query_method(query_method, criteria, settings)
      end

      def query(criteria, settings = {})
        settings = create_settings(settings)
        criteria = build_criteria(criteria, settings)

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

      # Query conditions can only be applied by a specific type of repo, like
      # a database or elastic search repo. Because of this we will fail if
      # this is not implemented
      #
      # @param result [Object] some type of query relation
      # @param criteria [SearchCriteria]
      # @param settings [Settings]
      # @return A query relation
      def apply_query_conditions(_result, _criteria, _settings)
        method_not_implemented_error
      end

      # Domain resolution can only be applied by specific repos. Because of
      # this we fail if is not implmented
      #
      # @param result [Object] some type of query relation
      # @param criteria [SearchCriteria]
      # @param settings [Settings]
      # @return A query relation
      def resolve_domains(_result, _criteria, _settings)
        method_not_implemented_error
      end

      # Factory method to create repo settings. This holds things like
      # pagination details, parser classes etc..
      #
      # @params settings [Hash,Settings]
      # @return Settings
      def create_settings(settings = {})
        return settings if settings.instance_of?(Settings)
        Settings.new(settings)
      end

      def build_criteria(criteria, settings)
        return criteria if criteria?(criteria)

        if criteria.is_a?(String)
          tree = settings.parser.parse(criteria)
          result = settings.transform.apply(tree)
          return result[:search]
        end

        unless criteria.is_a?(Hash)
          fail "criteria must be a String, Hash, or " +
               "Appfuel::Domain::SearchCriteria"
        end
        Criteria.build(criteria)
      end

      def criteria?(value)
        value.instance_of?(Criteria)
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

      private
      def method_not_implemented_error
        fail "must be implemented by a storage specific repository"
      end
    end
  end
end
