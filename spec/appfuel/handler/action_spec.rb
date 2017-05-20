module Appfuel::Handler
  RSpec.describe Action do
    context '.inherited' do
      it 'registers a handler in the container' do
        container = build_container(auto_register_classes: [])
        handler = setup(container, 'FooBar::Bar::Biz')
        expect(container[:auto_register_classes]).to include(handler)
      end
    end

    def setup(container = Dry::Container.new, class_name = "FooApp::Bar::Fiz")
      allow(Appfuel).to receive(:app_container) { container }
      allow(Action).to receive(:to_s) { class_name }
      handler = Class.new(Action)
      handler
    end
  end
end
