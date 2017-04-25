module Appfuel::Feature
  RSpec.describe Initializer do
    context '.call' do
      it 'setups up container dependencies when no feature key' do
        inputs = {
          features_path: 'my_root/features'
        }
        container = build_container(inputs)
        path = "#{inputs[:features_path]}/foo"
        key  = "features.foo"
        init = Initializer.new
        allow(init).to receive(:require).with(path) { true }
        allow(Appfuel).to receive(:run_initializers)
        expect(Appfuel).to(
          receive(:setup_container_dependencies).with(key, container)
        )

        init.call('foo', container)
      end

      it 'will not setup dependencies with the feature key exists' do
        inputs = {
          features_path: 'my_root/features'
        }
        container = build_container(inputs)
        container.register('features.foo', {})

        path = "#{inputs[:features_path]}/foo"
        key  = "features.foo"
        init = Initializer.new
        allow(init).to receive(:require).with(path) { true }
        allow(Appfuel).to receive(:run_initializers)
        expect(Appfuel).not_to(
          receive(:setup_container_dependencies).with(key, container)
        )

        init.call('foo', container)
      end

      it 'will not try to require feature when disable_require is true' do
        inputs = {
          features_path: 'my_root/features',
        }
        container = build_container(inputs)
        container.register('features.foo.disable_require', true)
        init = Initializer.new
        expect(init).not_to receive(:require)
        allow(Appfuel).to receive(:run_initializers)

        init.call('foo', container)
      end

      it 'will return false if already initialized' do
        inputs = {
          features_path: 'my_root/features',
        }
        container = build_container(inputs)
        container.register('features.foo.initialized', true)
        init = Initializer.new

        path = "#{inputs[:features_path]}/foo"
        allow(init).to receive(:require).with(path) { true }

        expect(init.call('foo', container)).to be false
      end

      it 'returns true when initializers are run' do
        inputs = {
          features_path: 'my_root/features',
        }
        container = build_container(inputs)
        init = Initializer.new

        path = "#{inputs[:features_path]}/foo"
        allow(init).to receive(:require).with(path) { true }
        allow(Appfuel).to receive(:run_initializers)

        expect(init.call('foo', container)).to be true
      end
    end
  end
end
