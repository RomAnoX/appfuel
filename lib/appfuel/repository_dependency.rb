module Appfuel
  module RepositoryDependency
    module ClassMethods

      def repo_dependencies
        @repo_dependencies ||= {}
      end

      def resolve_repos(results = Dry::Container.new)
        repo_dependencies.each do |name, result_key|
          key  = result_key || name
          results.register(key, resolve_global_repo(name))
        end

        results
      end

      def resolve_global_repo(name)
        name = "#{name.to_s.camelize}Repository"
        mod  = root_module
        fail "root module must be a Module" unless mod.is_a?(Module)
        repo_mod_name = 'Repositories'
        unless mod.const_defined?(repo_mod_name)
          fail "root module must have a #{repo_mod_name} module"
        end
        mod = mod.const_get(repo_mod_name)
        fail "Repo #{name} not found in #{mod}" unless mod.const_defined?(name)

        mod.const_get(name)
      end

      # @param name Symbol  snakecase name of the repository
      # @param opts Hash
      #   as:   custom name for repo
      def repo(name, opts = {})
        repo_dependencies[name.to_sym] = opts[:as]
      end

    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
