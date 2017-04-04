require_relative 'configuration/file_loader'
require_relative 'configuration/definition_dsl'

module Appfuel
  module Configuration
    def self.define(key, &block)
      definition = DefinitionDsl.new(key)
      definition.instance_eval(&block)
      definition
    end
  end
end
