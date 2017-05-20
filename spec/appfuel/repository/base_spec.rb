module Appfuel::Repository
  RSpec.describe Base do
    context '.inherited' do
      it 'registers a repository in the container' do
        container = build_container(auto_register_classes: [])
        repo = setup(container, 'FooApp::BarFeature::Repositories::FizDb')
        expect(container[:auto_register_classes]).to include(repo)
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
