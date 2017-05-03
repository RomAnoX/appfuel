require_relative 'repository/base'
require_relative 'repository/mapping_entry'
require_relative 'repository/mapping_dsl'
require_relative 'repository/mapper'
require_relative 'repository/mapping_registry'
require_relative 'repository/initializer'

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
    def self.mapping(domain_name, options = {}, &block)
      dsl = MappingDsl.new(domain_name, options)
      dsl.instance_eval(&block)

      dsl.entries.each do |entry|
        root      = entry.container_name || Appfuel.default_app_name
        container = Appfuel.app_container(root)
        mappings  = container['repository_mappings']

        domain_name = entry.domain_name
        mappings[domain_name] = {} unless mappings.key?(domain_name)

        entries = mappings[domain_name]
        entries[entry.domain_attr] = entry
      end
    end
  end
end
