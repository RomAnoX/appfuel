require_relative 'config/file_loader'
require_relative 'config/search'
require_relative 'config/populate'
require_relative 'config/definition_dsl'

module Appfuel
  module Config
    def self.define(key, &block)
      definition = DefinitionDsl.new(key)
      definition.instance_eval(&block)
      definition
    end
  end
end
