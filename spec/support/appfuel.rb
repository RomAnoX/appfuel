require 'awesome_print'
require 'appfuel'

RSpec.configure do |config|
  config.before(:each) do
    @dbs = Types::Db.container
    @types = Types.container
    dup_types = @types.dup
    dup_dbs   = @dbs.dup
    Types::Db.send(:instance_variable_set, :@container, dup_dbs)
    Types.send(:instance_variable_set, :@container, dup_types)
  end

  config.after(:each) do
    Types::Db.send(:instance_variable_set, :@container, @dbs)
    Types.send(:instance_variable_set, :@container, @types)
  end

  config.include AppfuelHelpers
end
