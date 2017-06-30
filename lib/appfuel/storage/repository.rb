require 'parslet'
require 'parslet/convenience'

require_relative 'repository/base'

require_relative 'repository/mapping_entry'
require_relative 'repository/storage_map'
require_relative 'repository/mapping_dsl'
require_relative 'repository/mapping_collection'

require_relative 'repository/mapper'
require_relative 'repository/initializer'
require_relative 'repository/runner'
require_relative 'repository/expr'
require_relative 'repository/expr_conjunction'
require_relative 'repository/order_expr'
require_relative 'repository/criteria'
require_relative 'repository/expr_parser'
require_relative 'repository/search_parser'
require_relative 'repository/expr_transform'
require_relative 'repository/search_transform'
require_relative 'repository/settings'

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
    def self.mapping(domain_name, to:, model:, **opts, &block)
      dsl = MappingDsl.new(domain_name, to: to, model: model, **opts)
      dsl.instance_eval(&block)

      container   = Appfuel.app_container(dsl.container_name)
      mappings    = container['repository_mappings']
      storage_map = dsl.create_storage_map
      mappings.load(storage_map)
    end

    def self.entity_builder(domain_name, type, opts = {}, &block)
      fail "entity builder must be used with a block" unless block_given?

      root = opts[:root] || Appfuel.default_app_name
      repo = create_repo(type, domain_name)
      repo.class.load_path_from_container_namespace("#{root}.#{domain_name}")

      app_container = Appfuel.app_container(root)
      category      = "domain_builders.#{type}"
      builder_key   = repo.qualify_container_key(domain_name, category)
      app_container.register(builder_key, create_builder(repo, &block))
    end

    def self.create_repo(type, domain_name)
      repo_class = "Appfuel::#{type.to_s.classify}::Repository"
      unless Kernel.const_defined?(repo_class)
        fail "Could not find #{repo_class} for entity builder #{domain_name}"
      end
      Kernel.const_get(repo_class).new
    end

    def self.create_builder(repo, &block)
      ->(storage, criteria) {
        repo.instance_exec(storage, criteria, &block)
      }
    end
  end
end
