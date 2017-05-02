module Appfuel
  class DbModel < ActiveRecord::Base
    self.abstract_class = true
    extend Appfuel::Application::ContainerKey
    extend Appfuel::Application::ContainerClassRegistration

    def self.inherited(klass)
      super
      register_container_class(klass)
    end

    def entity_attributes
      attributes.symbolize_keys.select {|_,value| !value.nil?}
    end
  end
end
