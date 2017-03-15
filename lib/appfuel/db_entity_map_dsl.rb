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
      @map         = {}
      fail "db_name can not be empty" if @db_name.empty?
    end

    def map_data
      @map
    end

    #
    # map has an entity attribute
    # map has a column name
    # map belongs to an entity
    # map belongs to a db_class
    # map has properties used during building
    #   skip_to_entity: ignore this entry when building an entity
    #   skip_to_db: ignore this entry when build db hash
    #   computed_property: use this closure instead of attribute value
    #   computed_value: use this closure with the attribute value
    def map(name, entity_method = nil, opts = {})
      entity_method = name if entity_method.nil?

      value = case entity_method
              when Proc
                label = name
                if opts.is_a?(Hash) && opts[:as]
                  label = opts[:as]
                end
                {call: entity_method, name: label.to_s, skip: false}
              when String, Symbol
                entity_method = entity_method.to_s
                entity_method.strip!
                if entity_method.empty?
                  fail ArgumentError, "entity attr is empty for #{name}"
                end

                if opts.is_a?(Hash) && opts[:skip] == true
                  {call: nil, name: entity_name, skip: true}
                else
                  entity_method
                end
              else
                msg =  "attr must be a string, symbol or proc for #{name}"
                fail ArgumentError, msg
              end

      @map[name.to_s] = value
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
