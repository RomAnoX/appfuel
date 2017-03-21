module Appfuel
  class Command < Handler
    class << self
      extend RepositoryDependencyInjection
      # The command class will always be in the Commands namespace below
      # the feature namespace.
      #
      # TopModule::FeatureModule::Commands::CmdClass
      #
      # @return Module
      def feature_module
        parent.parent
      end

      def resolve_dependencies(results = Dry::Container.new)
        super
        resolve_container(results)
        resolve_domains(results)
        resolve_db_models(results)
        resolve_repos(results)
        results
      end
    end

  end
end
