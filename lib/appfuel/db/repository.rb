module Appfuel
  module Db
    class Repository
      include RootModule
      include Mapper
      attr_reader :response_handler

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

      def transaction(key, &block)
        fail "transaction requires a block" unless block_given?
        db = repo_mapper.db_class(key)
        db.transaction do
          block.call(db)
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
