require 'rake'

module Appfuel
  module Db
    module MigrationsInitializer

      def self.call(settings = {})
        root_name = settings[:root_name] || Appfuel.default_app_name
        container = Appfuel.app_container(root_name)

        config    = container[:config]
        root_path = container[:root_path]
        env       = container[:env]
        db_path   = config[:db][:path]
        db_config = config[:db][:main]

        migrations_paths = config[:db][:migrations_path]

        db_tasks = settings.fetch(:db_tasks) {
          ActiveRecord::Tasks::DatabaseTasks
        }

        db_migrator = settings.fetch(:db_migrator) {
          ActiveRecord::Migrator
        }

        active_record_base = settings.fetch(:active_record_base) {
          ActiveRecord::Base
        }

        active_record_base.configurations = {env => db_config}
        db_tasks.root   = root_path
        db_tasks.env    = env
        db_tasks.db_dir = db_path
        db_tasks.migrations_paths = migrations_paths
        db_migrator.migrations_paths = migrations_paths
        db_tasks.database_configuration = {env => db_config}
        db_tasks.current_config = db_config
      end
    end
  end
end
