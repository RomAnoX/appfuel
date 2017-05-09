require 'rake'
require_relative 'migration_initializer'
require_relative 'migration_tasks'

module Appfuel
  module Db
    module MigrationRunner
      def self.call(cmd, data = {})
        tasks = MigrationTasks.new
        tasks.install_tasks
        Rake::Task[cmd].invoke
      end
    end
  end
end
