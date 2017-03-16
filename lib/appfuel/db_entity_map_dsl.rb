module Appfuel
  # A mapping dsl that allows the collection of database columns to domain
  # attributes. The reason this dsl is separated from the DbEntityMapper
  # is due to the fact that we use method_missing for collecting column names
  # and don't want any incorrect method_missing calls to be confused when
  # collecting mapped values vs when defining them.
  class DbEntityMapDsl
    attr_reader :entity_name, :entity_key, :map_key, :db_name

    def initialize(entity_name, db_name, key = nil)
      @entity_name = entity_name.to_s
      @entity_key  = parse_entity_name(@entity_name)
      @db_name     = db_name.to_s
      @map_key     = key || entity_key
      @map         = []
      fail "db_name can not be empty" if @db_name.empty?
    end

    def map_data
      @map
    end

    def map(name, entity_attr = nil, opts = {})
      entity_attr = name if entity_attr.nil?

      data = opts.merge({
        entity: entity_name,
        entity_attr: entity_attr,
        db_class: db_name,
        db_column: name,
      })

      @map << DbEntityMapEntry.new(data)
    end

    def parse_entity_name(name)
      fail "entity name can not be empty" if name.empty?
      name = name.split('.').last
      name.strip!

      fail "entity basename can not be empty" if name.empty?
      name
    end
  end
end
