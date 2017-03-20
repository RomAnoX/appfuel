module Appfuel
  module Domain
    module DependencyInjectionDsl
      def domain_dependencies
        @domain_dependencies ||= {global: {}, feature: {}}
      end

      def resolve_domains(results = Dry::Container.new)
        domain_dependencies[:feature].each do |name, result_key|
          feature_name = feature_module.name.underscore.split('/').last
          domain_key   = "#{feature_name}.#{name}"
          key  = result_key || name
          results.register(key, Types[domain_key])
        end

        domain_dependencies[:global].each do |name, result_key|
          key  = result_key || name
          results.register(key, Types[name.to_s])
        end

        results
      end

      def domain(name, opts = {})
        location = opts[:global] == true ? :global : :feature
        domain_dependencies[location][name] = opts[:as]
      end
    end
  end
end
