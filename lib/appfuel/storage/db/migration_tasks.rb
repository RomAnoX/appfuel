require 'rake'
module Appfuel
  module Db
    class MigrationTasks
      include Rake::DSL

      def install_tasks
        MigrationsInitializer.call
        load "active_record/railties/databases.rake"

        namespace :db do
          task :environment do
            # We do all our initialization first this is just to make
            # rails happy
          end
        end
      end
    end
  end
end
