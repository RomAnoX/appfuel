module Appfuel::Feature
  RSpec.describe ActionLoader do
    context '#call' do
      it 'fails when namespace is not found' do
        namespace = 'features.foo.actions.bar'
        container = build_container
        loader    = ActionLoader.new
        msg = '[ActionLoader] Could not load action at features.foo.actions.bar'
        expect {
          loader.call(namespace, container)
        }.to raise_error(RuntimeError, msg)
      end

      it 'returns the registered action' do
        action    = 'i am an action'
        namespace = 'features.foo.actions.bar'
        container = build_container
        container.register(namespace, action)
        loader = ActionLoader.new
        expect(loader.call(namespace, container)).to eq(action)
      end
    end
  end
end
