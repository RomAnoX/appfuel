require 'appfuel'
require_relative 'helpers'


RSpec.configure do |config|
  config.before(:each) do

    @types = Types.container
    @app_container    = Appfuel.app_container
    @default_app_name = Appfuel.default_app_name
    @framework_container = Appfuel.framework_container

    Types.send(:instance_variable_set, :@container, @types.dup)
    Types.send(
      :instance_variable_set,
      :@framework_container,
      @framework_container.dup)
  end

  config.after(:each) do
    Types.send(:instance_variable_set, :@container, @types)
    Appfuel.framework_container = @framework_container
  end

  config.include Appfuel::TestingSpec::Helpers
end
