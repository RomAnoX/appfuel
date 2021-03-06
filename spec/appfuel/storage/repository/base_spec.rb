module Appfuel::Repository
  RSpec.describe Base do
    context '.inherited' do
      it 'registers a repository in the container' do
        container = build_container
        repo = setup(container, 'FooApp::BarFeature::Repositories::FizDb')
        expect(container[:auto_register_classes]).to include(repo)
      end
    end

    context '.container_class_type' do
      it 'has a type of "repositories"' do
        expect(setup.container_class_type).to eq('repositories')
      end
    end

    context '.create_mapper' do
      it 'creates a repository mapper' do
        repo = setup
        expect(repo.create_mapper).to be_an_instance_of(mapper_class)
      end

      it 'creates a repository mapper with a map' do
        repo = setup
        map  = MappingCollection.new
        mapper = repo.create_mapper(map)
        expect(mapper.map).to eq(map)
      end

      it 'creates a mapper with the container_container_root_name' do
        repo = setup
        mapper = repo.create_mapper
        expect(mapper.container_root_name).to eq(repo.container_root_name)
      end
    end

    context '.mapper' do
      it 'creates a mapper when none exists' do
        repo = setup
        result = 'I am a faked out mapper instance'
        expect(repo).to receive(:create_mapper).with(no_args) { result }

        expect(repo.mapper).to eq(result)
      end

      it 'assigns a custom mapper' do
        repo = setup
        mapper = 'i am a mapper'
        repo.mapper = mapper
        expect(repo.mapper).to eq(mapper)
      end
    end

    context '.cache' do
      it 'delegates the cache to the app_container' do
        container = build_container
        repo = setup(container)
        cache = {}
        expect(container).to receive(:[]).with(:repository_cache) { cache }
        expect(repo.cache).to eq(cache)
      end
    end

    context '#mapper' do
      it 'delegates to the class method' do
        repo_class = setup
        repo = repo_class.new
        result = 'some mapper'
        expect(repo_class).to receive(:mapper).with(no_args) { result }
        expect(repo.mapper).to eq(result)
      end
    end

    context '#execute_query_method' do
      it 'fails when then method is not implemented on the concrete class' do
        repo = setup.new
        criteria = 'some criteria'
        settings = 'some settings'
        msg = 'Could not execute query method (foo)'
        expect {
          repo.execute_query_method('foo', criteria, settings)
        }.to raise_error(msg)
      end

      it 'executes the method' do
        repo = setup.new
        criteria = 'some criteria'
        settings = 'some settings'
        method   = 'foo'
        mock_results = 'lots of good results'
        repo.define_singleton_method(:foo) do |_criteria, _settings|
          mock_results
        end

        allow(repo).to receive(:respond_to?).with(method) { true }

        allow(repo).to receive(:respond_to?).with(:public_send, true) { true }
        query_results = repo.execute_query_method(method, criteria, settings)
        expect(query_results).to eq(mock_results)
      end
    end

    context '#query_setup' do
      it 'users the criteria to define a query method for the domain' do
        repo     = setup.new
        criteria = instance_double(criteria_class)
        settings = 'some settings object'
        domain   = 'user'
        method   = "#{domain}_query"
        results  = 'some query relation'
        allow(criteria).to receive(:domain_basename).with(no_args) { domain }
        expect(repo).to(
          receive(:execute_query_method).with(method, criteria, settings)
        ) { results }

        expect(repo.query_setup(criteria, settings)).to eq(results)
      end
    end

    context '#apply_query_conditions' do
      it 'always fails because this is generic repository' do
        repo     = setup.new
        relation = 'some query relation'
        criteria = instance_double(criteria_class)
        settings = 'some settings object'
        msg = "must be implemented by a storage specific repository"
        expect {
          repo.apply_query_conditions(relation, criteria, settings)
        }.to raise_error(msg)
      end
    end

    context '#build_domains' do
      it 'always fails because this is generic repository' do
        repo     = setup.new
        relation = 'some query relation'
        criteria = instance_double(criteria_class)
        settings = 'some settings object'
        msg = "must be implemented by a storage specific repository"
        expect {
          repo.build_domains(relation, criteria, settings)
        }.to raise_error(msg)
      end
    end

    context '#criteria?' do
      it 'returns true when the value is a criteria' do
        repo     = setup.new
        criteria = instance_double(criteria_class)
        allow(criteria).to receive(:instance_of?).with(criteria_class) { true }
        expect(repo.criteria?(criteria)).to be(true)
      end

      it 'returns false when the value is not a criteria' do
        repo     = setup.new
        criteria = instance_double(criteria_class)
        allow(criteria).to receive(:instance_of?).with(criteria_class) { false }
        expect(repo.criteria?(criteria)).to be(false)
      end
    end

    context '#create_settings' do
      it 'returns the settings object if its a settings object' do
        settings = create_settings
        repo     = setup.new
        expect(repo.create_settings(settings)).to eq(settings)
      end

      it 'creates settings with an empty hash' do
        settings = create_settings({})
        expect(settings).to be_an_instance_of(settings_class)
      end

      it 'creates a settings object with settings data' do
        data = { page: 3, per_page: 2 }
        repo = setup.new
        settings = repo.create_settings(data)
        expect(settings).to be_an_instance_of(settings_class)
        expect(settings.page).to eq(3)
        expect(settings.per_page).to eq(2)
      end
    end

    context '#build_criteria' do
      it 'returns the criteria when a criteria is given' do
        settings = instance_double(settings_class)
        criteria = criteria_class.new('foo.bar')
        repo = setup.new
        expect(repo.build_criteria(criteria, settings)).to eq(criteria)
      end

      it 'builds a criteria from a string' do
        expr = 'foo.bar filter id = 6'
        repo = setup.new
        settings = repo.create_settings
        criteria = repo.build_criteria(expr, settings)
        expect(criteria).to be_an_instance_of(criteria_class)
        expect(criteria.domain_name).to eq('foo.bar')

        expr = criteria.filters
        expect(expr.to_s).to eq('features.foo.bar.id = 6')
      end

      it 'builds a criteria form a hash' do
        data = {
          domain: 'foo.bar',
          filters: 'id = 6',
          order: 'id desc',
          limit: 6
        }
        repo = setup.new
        settings = repo.create_settings
        criteria = repo.build_criteria(data, settings)
        expect(criteria).to be_an_instance_of(criteria_class)
        expect(criteria.domain_name).to eq('foo.bar')

        expr = criteria.filters
        expect(expr.to_s).to eq('features.foo.bar.id = 6')
        order = criteria.order_by
        expect(order.size).to eq(1)
        expect(order[0].attr_list).to eq(['features','foo','bar','id'])
        expect(order[0].op).to eq('desc')
        expect(criteria.limit).to eq(6)
      end
    end

    def criteria_class
      Criteria
    end

    def mapper_class
      Mapper
    end

    def settings_class
      Settings
    end

    def create_settings(settings = {})
      settings_class.new(settings)
    end

    def setup(container = Dry::Container.new, class_name = "FooApp::Bar::Fiz")
      container.register(:auto_register_classes, [])
      container.register(:repository_cache, {})

      allow(Appfuel).to receive(:app_container) { container }
      allow(Base).to receive(:to_s) { class_name }
      repo = Class.new(Base)
      repo
    end
  end
end
