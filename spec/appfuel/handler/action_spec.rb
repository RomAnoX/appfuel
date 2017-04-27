module Appfuel::Handler
  RSpec.describe Action do
    context '.inherited' do
      it 'registers a handler in the container' do
        container = build_container
        handler = setup(container, 'FooBar::Bar::Biz')
        expect(container['features.bar.actions.biz']).to eq(handler)
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
