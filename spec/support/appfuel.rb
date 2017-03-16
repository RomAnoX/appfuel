require 'awesome_print'
require 'appfuel'


RSpec.configure do |config|
  config.before(:each) do
    @db_map = Appfuel::DbMappingRegistry.map

    @dbs = Types::Db.container
    @types = Types.container


    Types::Db.send(:instance_variable_set, :@container, @dbs.dup)
    Types.send(:instance_variable_set, :@container, @types.dup)
    Appfuel::DbMappingRegistry.map = @db_map.dup
  end

  config.after(:each) do
    Types::Db.send(:instance_variable_set, :@container, @dbs)
    Types.send(:instance_variable_set, :@container, @types)
    Appfuel::DbMappingRegistry.map = @db_map
  end

  config.include AppfuelHelpers
end

