require 'awesome_print'
require 'appfuel'


RSpec.configure do |config|
  config.before(:each) do

    @db_map = Appfuel::Db::MappingRegistry.map
    @dbs    = Types::Db.container
    @types  = Types.container


    Types::Db.send(:instance_variable_set, :@container, @dbs.dup)
    Types.send(:instance_variable_set, :@container, @types.dup)
    Appfuel::Db::MappingRegistry.map = @db_map.dup
    Appfuel.framework_container = Dry::Container.new
  end

  config.after(:each) do
    Types::Db.send(:instance_variable_set, :@container, @dbs)
    Types.send(:instance_variable_set, :@container, @types)
    Appfuel::Db::MappingRegistry.map = @db_map
  end

  config.include AppfuelHelpers
end

