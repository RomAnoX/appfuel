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
        map  = {'foo' => 'bar'}
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

    def mapper_class
      Mapper
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
