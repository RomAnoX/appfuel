require 'appfuel'
require_relative 'helpers'


RSpec.configure do |config|
  config.before(:each) do

    @types  = Types.container
    Types.send(:instance_variable_set, :@container, @types.dup)
    Appfuel.framework_container = Dry::Container.new
  end

  config.after(:each) do
    Types.send(:instance_variable_set, :@container, @types)
  end

  config.include Appfuel::TestingSpec::Helpers
end
