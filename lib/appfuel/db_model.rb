module Appfuel
  class DbModel < ActiveRecord::Base
    self.abstract_class = true
    def self.inherited(klass)
      super

      key = klass.name.underscore.split('/').last
      Types::Db.register(key, klass)
    end

    def entity_attributes
      attributes.symbolize_keys.select {|_,value| !value.nil?}
    end
  end
end
