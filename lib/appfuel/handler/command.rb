module Appfuel
  module Handler
    class Command < Base
      class << self
        def resolve_dependencies(results = Dry::Container.new)
=begin
          super
          resolve_container(results)
          resolve_domains(results)
          resolve_db_models(results)
          resolve_repos(results)
          results
=end
        end
      end
    end
  end
end
