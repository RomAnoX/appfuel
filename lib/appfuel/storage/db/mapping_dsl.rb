module Appfuel
  module Db
    # A mapping dsl that allows the collection of database columns to domain
    # attributes. The reason this dsl is separated from the DbEntityMapper
    # is due to the fact that we use method_missing for collecting column names
    # and don't want any incorrect method_missing calls to be confused when
    # collecting mapped values vs when defining them.
    class MappingDsl
      attr_reader :entity_name, :db_name, :entries, :entry_class

      def initialize(entity_name, db_name, entry_class = MappingEntry)
        @entity_name = entity_name.to_s
        @db_name     = db_name.to_s
        @entry_class = entry_class
        @entries     = []
        fail "db_name can not be empty" if @db_name.empty?
        fail "entity name can not be empty" if @entity_name.empty?
      end

      def map(name, entity_attr = nil, opts = {})
        entity_attr = name if entity_attr.nil?

        data = opts.merge({
          entity: entity_name,
          entity_attr: entity_attr,
          db_class: db_name,
          db_column: name,
        })

        @entries << entry_class.new(data)
      end
    end
  end
end
