require 'rake'
module Appfuel
  module Db
    class MigrationTasks
      include Rake::DSL

      def install_tasks
        load "active_record/railties/databases.rake"

        namespace :db do
          task :environment do
            MigrationsInitializer.call
          end
        end
      end
    end
  end
end
