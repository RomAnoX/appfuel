module Appfuel::Repository
  RSpec.xdescribe Runner do
    context '#new' do
      it 'requires the repo namespace and criteria class' do
        repo_ns  = 'Foo::Bar'
        runner   = Runner.new(repo_ns, criteria_class)
        expect(runner.repo_namespace).to eq(repo_ns)
        expect(runner.criteria_class).to eq(criteria_class)
      end
    end

    context '#exists?' do
      it 'fails when repository does not exist' do
        repo_ns  = 'Foo::Bar'
        runner   = Runner.new(repo_ns, criteria_class)
        msg = 'RepositoryRunner: failed - repo Foo::Bar::DomainRepository not defined'
        expect {
          runner.exists?('domain', id: 123)
        }.to raise_error(RuntimeError, msg)
      end

      xit 'delegates exists to repo.exists? passing the criteria' do
        repo_ns         = 'Foo::Bar'
        runner          = Runner.new(repo_ns, criteria_class)
        repo_class_name = 'Foo::Bar::DomainRepository'
        repo_class      = class_double(Db::Repository)
        repo            = instance_double(Db::Repository)
        criteria        = instance_double(criteria_class)
        entity_key      = 'domain'
        attribute       = 'id'
        value           = true

        allow_const_defined(Kernel, repo_class_name, true)
        allow_const_get(Kernel, repo_class_name, repo_class)
        allow(repo_class).to receive(:new).with(no_args) { repo }

        allow(criteria_class).to receive(:new).with(entity_key, {}) { criteria }
        allow(criteria).to receive(:exists).with(attribute, value) { criteria }
        allow(criteria).to receive(:repo_name).with(no_args) { "DomainRepository" }
        allow(repo).to receive(:exists?).with(criteria) { true }

        expect(runner.exists?(entity_key, attribute => value)).to eq(true)
      end
    end

    context '#query' do
      it 'fails when repository does not exist' do
        repo_ns = 'Foo::Bar'
        runner = Runner.new(repo_ns, criteria_class)
        msg = 'RepositoryRunner: failed - repo Foo::Bar::DomainRepository not defined'

        criteria = criteria_class.new('domain').where('id', eq: 123)
        expect {
          runner.query(criteria)
        }.to raise_error(RuntimeError, msg)
      end
    end

    def criteria_class
      @criteria_class ||= Domain::Criteria
    end
  end
end
