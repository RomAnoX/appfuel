module Appfuel
  RSpec.describe(RepositoryDependencyInjection) do
    it 'has no dependencies by default' do
      obj = Class.new do
        extend RepositoryDependencyInjection
      end

      expect(obj.repo_dependencies).to eq({})
    end

    context '#repo' do
      it 'declares feature dependency without an alias' do
        object = setup(:foo)
        expect(object.repo_dependencies).to eq({foo: nil})
      end

      it 'declares feature dependency with an alias' do
        object = setup(:foo, as: :bar)
        expect(object.repo_dependencies).to eq({foo: :bar})
      end
    end

    context '#resolve_repos' do
      it 'finds an existing feature repo' do
        object = setup(:foo)

        container = object.resolve_repos
        expect(container.key?(:foo)).to be true
      end

      it 'fails when global module is not a Module' do
        object = setup(:foo)

        root_mod = double(:not_module)
        object.class_eval do
          define_singleton_method(:root_module) { root_mod }
        end

        expect {
          object.resolve_repos
        }.to raise_error StandardError, "root module must be a Module"
      end

      it 'fails when global repository module  is not found' do
        object   = setup(:foo)
        root_mod  = class_double(Module)
        repo_mod = class_double(Module)
        object.class_eval do
          define_singleton_method(:root_module) { root_mod }
        end

        allow_repo_module(root_mod, repo_mod, false)

        msg = "root module must have a Repositories module"
        expect {
          object.resolve_repos
        }.to raise_error RuntimeError, msg
      end

      it 'fails when repository is not found' do
        object   = setup(:foo)
        root_mod  = class_double(Module)
        repo_mod = class_double(Module)

        object.class_eval do
          define_singleton_method(:root_module) { root_mod }
        end
        allow_repo_module(root_mod, repo_mod)
        allow_repo(repo_mod, "FooRepository", repo_mod, false)


        msg = "Repo FooRepository not found in #{root_mod}"
        expect {
          object.resolve_repos
        }.to raise_error RuntimeError, msg
      end



    end

    def setup(name, opts = {})
      obj = Class.new do
        extend RepositoryDependencyInjection
      end

      obj.repo(name, opts)

      repo_name = "#{name.to_s.camelize}Repository"
      root_mod  = class_double(Module)
      repo_mod  = class_double(Module)

      allow_repo_module(root_mod, repo_mod)
      allow_repo(repo_mod, repo_name, double(:repo))

      obj.class_eval do
        define_singleton_method :root_module do
          root_mod
        end
      end

      obj
    end

    def allow_repo_module(root_mod, repo_mod, exists = true)
      allow(root_mod).to receive(:const_defined?).with('Repositories') { exists }
      allow(root_mod).to receive(:const_get).with('Repositories') { repo_mod }
    end

    def allow_repo(repo_mod, repo_name, repo, exists = true)
      allow(repo_mod).to receive(:const_defined?).with(repo_name) { exists }
      allow(repo_mod).to receive(:const_get).with(repo_name) { repo }
    end
  end
end
