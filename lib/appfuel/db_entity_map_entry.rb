module Appfuel
  #
  # map has an entity attribute
  # map has a column name
  # map belongs to an entity
  # map belongs to a db_class
  # map has properties used during building
  #   skip_to_entity: ignore this entry when building an entity
  #   skip_to_db: ignore this entry when build db hash
  #   computed_attr: use this closure instead of attribute value
  #   computed_attr_expect_value: use this closure with the attribute value
  #   virtual: does not exist in an entity but exposed via the criteria.
  #            this happens when you many to many joins
  #
  class DbEntityMapEntry
    attr_reader :entity, :entity_attr, :db_class, :db_column

    def initialize(data)
      unless data.respond_to?(:fetch)
        fail "Map entry data must respond to :to_h"
      end

      data = data.to_h
      self.entity = data.fetch(:entity) do
        fail "entity is required"
      end

      self.db_class = data.fetch(:db_class) do
        fail "db_class is required"
      end

      self.db_column = data.fetch(:db_column) do
        fail "db_column is required"
      end

      self.entity_attr = data.fetch(:entity_attr) do
        fail "entity_attr is required"
      end

      self.skip_to_entity = data.fetch(:skip_to_entity) { false }
      self.skip_to_db     = data.fetch(:skip_to_db) { false }
      self.skip_all       = data.fetch(:skip_all) { false }
      if data.key?(:computed_attr)
        self.computed_attr(data[:computed_attr])
      end

      if data.key?(:computed_attr_expect_value)
        self.computed_attr(data[:computed_attr_expect_value], true)
      end
    end

    private
    def entity=(value)
      @entity = value.to_s
    end

    def db_class=(value)
      @db_class = value.to_s
    end

    def db_column=(value)
      @db_column = value.to_s
    end

    def entity_attr=(value)
      @entity_attr = value.to_s
    end

    def skip_to_entity=(value)
      @skip_to_entity = value == true ? true : false
    end

    def skip_to_db=(value)
      @skip_to_db = value == true ? true : false
    end

    def skip_all=(value)
      @skip_all = value == true ? true : false
      if @skip_all
        self.skip_to_entity(true)
        self.skip_to_db(true)
      end
    end

    def computed_attr(value, expect_value = false)
      unless value.lambda?
        fail "computed attributes require a lambda as a value"
      end

      if expect_value && value.arity != 1
        fail "computed attribute lambda's must accept 1 param"
      end

      @computed_attr_lambda = value
    end
  end
end
