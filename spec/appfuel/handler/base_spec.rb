module Appfuel::Handler
  RSpec.describe Base do
    context '.inherited' do
      it 'registers a handler in the container' do
        container = build_container
        allow(Appfuel).to receive(:app_container) { container }
        handler = setup
        expect(container['features.bar.fiz']).to eq(handler)
      end
    end

    def setup(class_name = "FooApp::Bar::Fiz")
      allow(Base).to receive(:to_s) { class_name }
      handler = Class.new(Base)
      handler
    end
  end
end
