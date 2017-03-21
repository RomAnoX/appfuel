module Appfuel
  module Db
    class Repository
      include RootModule

      attr_reader :response_handler

      def query(criteria)
        return execute_criteria(criteria) if criteria.exec?

        begin
          relation = build_relation(criteria)

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

      def create_entity_not_found(criteria)
        EntityNotFound.new(entity_name: criteria.domain_name)
      end

      def handle_empty_relation(criteria, relation)
        if criteria.error_on_empty_dataset?
          return error(criteria.domain => ["#{criteria.domain} not found"])
        end

        if criteria.single?
          return create_entity_not_found(criteria)
        end
      end

      def error(msg)
        Errors.new(msg)
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

      # General create will create an entity in the database
      # 1. find the db_model fail otherwise
      # 2. map attributes from entity to db
      # 3. delegate create call
      # 4. update entity with id
      def db_create(name, domain, opts = {})
        begin
          mapper  = repo_mapper
          db      = mapper.db_class(name)
          data    = mapper.to_db(domain, opts)
          result  = db.create(data)
          build_entity(name, result, mapper)
        rescue => e
          raise_error e, "db_create failed for #{name}: #{e.class} #{e.message}"
        end
      end

      def db_update(name, entity, criteria = nil)
        validate_entity_id(entity)
        begin
          mapper  = repo_mapper
          db      = mapper.db_class(name)
          data    = mapper.to_db(entity)
          id      = data[name.to_sym]['id']
          result = db.update(id, data.except('id'))
          build_entity(name, result, mapper)
        rescue => e
          raise_error(e, "update failed: #{e.message}")
        end
      end

      def delete(name, entity, criteria = nil)
        validate_entity_id(entity)
        begin
          mapper  = repo_mapper
          db      = mapper.db_class(name)
          data    = mapper.to_db(entity)
          id      = data[name.to_sym]['id']
          !!db.delete(id)
        rescue => e
          raise_error(e, "delete failed for #{name}. #{e.message}")
        end
      end

      def repo_mapper
        self.class.mapper
      end

      def db_class(map_key)
        repo_mapper.db_class(map_key)
      end

      def transaction(key, &block)
        fail "transaction requires a block" unless block_given?
        db = repo_mapper.db_class(key)
        db.transaction do
          block.call(db)
        end
      end

      def exists?(criteria)
        key  = criteria.domain.to_s
        expr = criteria.exists_expr
        key  = "#{criteria.domain}.#{expr.domain}" if expr.domain?
        exists_in_db?(key, expr.value)
      end

      def exists_in_db?(name, conditions)
        db = repo_mapper.db_class(name)
        db.exists?(conditions)
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

      private

      def create_default_pager
        Types['pager'][{}]
      end

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
