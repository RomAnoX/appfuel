module Appfuel::Handler
  RSpec.describe Base do
    context '.inherited' do
      it 'registers a handler in the container' do
        container = build_container
        handler = setup(container)
        expect(container['features.bar.fiz']).to eq(handler)
      end
    end

    context 'response_handler' do
      it 'creates a new Appfuel::ResponseHandler by default' do
        expect(Appfuel::ResponseHandler).to receive(:new).with(no_args)
        handler = setup
        handler.response_handler
      end

      it 'returns an instance of Appfuel::ResponseHandler' do
        handler = setup
        expect(handler.response_handler).to(
          be_an_instance_of(Appfuel::ResponseHandler)
        )
      end
    end
    def setup(container = Dry::Container.new, class_name = "FooApp::Bar::Fiz")
      allow(Appfuel).to receive(:app_container) { container }
      allow(Base).to receive(:to_s) { class_name }
      handler = Class.new(Base)
      handler
    end
  end
end
