module Appfuel
  module Config
    # Defines database configuration. This is designed to hold more than one
    # database connection which is why they are named invidually. We are using
    # active record so the config is taylored to that style connection.
    #
    # Configuration Overview
    #
    # pool:     Managed connection which controls the amount of thread access to
    #           a limited number of database connections
    # adapter:  We always use postgres, rarely changes
    # encoding: We always use unicode, rarely changes
    # database  Name of the database
    # username  Name of the database user
    # password  Database password
    # host      Location of the database server
    #
    # @return Defintion
    def self.db_definition
      define :db do
        validator {
          required(:main).filled(:hash?)
          required(:path).filled(:str?)
          required(:seed_path).filled(:str?)
          required(:migrations_path).filled(:str?)
        }

        db_path = 'db'
        defaults path: db_path,
          migrations_path: "#{db_path}/migrations",
          seed_path: 'db/seed'

        define :main do
          defaults pool:     5,
            adapter: 'postgresql',
            encoding: 'unicode',
            schema_format: 'sql'

          validator do
            required(:schema_search_path).filled(:str?)
            required(:schema_format).filled(:str?)
            required(:database).filled(:str?)
            required(:username).filled(:str?)
            required(:password).filled(:str?)
            required(:host).filled(:str?)
            required(:adapter).filled(:str?)
            optional(:pool).filled(:int?)
            optional(:encoding).filled(:str?)
            optional(:port).filled(:int?)
          end
        end
      end
    end
  end
end
