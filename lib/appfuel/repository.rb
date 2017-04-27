require_relative 'repository/base'
require_relative 'repository/mapping_entry'

module Appfuel
  module Repository
    # Mapping uses the map_dsl_class to define and map mapping entries
    # into the mapping registry
    #
    # @example Simple mapping
    #   mapping 'foo.bar', db: foo_table_one do
    #     map 'id'
    #     map 'project_user_id', 'user.id'
    #   end
    #
    #   Note: When no :key value is given to options then the entity base
    #         name is used. The following would be equivalent:
    #
    #   mapping 'offers.offer', db: foo_table_two do
    #     ...
    #   end
    #
    # @param entity_name [String] domain name of the entity we are mapping
    # @param db_class [String] name of the database class used in mapping
    # @return [DbEntityMapper]
    def mapping(domain_name, persistence_classes = {}, &block)
      fail "opts must be a hash" unless opts.is_a?(Hash)
      dsl = MappingDsl.new(entity_name, db_class)
      dsl.instance_eval(&block)

      dsl.entries.each {|entry| MappingRegistry << entry}
    end
  end
end
