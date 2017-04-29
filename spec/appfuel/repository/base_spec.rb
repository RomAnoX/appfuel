module Appfuel::Repository
  RSpec.describe Base do
    context '.inherited' do
      it 'registers a repository in the container' do
        container = build_container
        repo = setup(container, 'FooApp::BarFeature::Repositories::FizDb')
        expect(container['features.bar_feature.repositories.fiz_db']).to eq(repo)
      end
    end

    context 'registry_from_app_container' do
      it 'gets the registry from the application container' do
        registry  = double('i am a registry')
        container = build_container(repository_registry: registry)
        repo = setup(container, 'FooApp::BarFeature::Repositories::FizDb')

        expect(repo.registry_from_app_container).to eq(registry)
      end
    end
    context 'registry' do
      it 'assigns the registry from the app container by default' do
        registry  = double('i am a registry')
        container = build_container(repository_registry: registry)
        repo = setup(container, "Foo::Bar::Repositories::Fiz")
        expect(repo.registry).to eq(registry)
      end

      it 'contains the same registry for two different classes' do
        registry  = double('i am a registry')
        container = build_container(repository_registry: registry)
        repo1 = setup(container, "Foo::Bar::Repositories::Fiz")
        repo2 = setup(container, "Foo::Bar::Repositories::Baz")
        expect(repo1.registry.object_id).to eq(repo2.registry.object_id)
      end
    end

    context 'registry=' do
      it 'assigns a registry manually' do
        registry = 'i am a registry'
        repo = setup
        repo.registry = registry
        expect(repo.registry).to eq(registry)
      end
    end

    def setup(container = Dry::Container.new, class_name = "FooApp::Bar::Fiz")
      allow(Appfuel).to receive(:app_container) { container }
      allow(Base).to receive(:to_s) { class_name }
      repo = Class.new(Base)
      repo
    end
  end
end
