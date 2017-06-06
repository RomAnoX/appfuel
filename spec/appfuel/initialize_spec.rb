module Appfuel
  RSpec.describe Initialize do
    context '.define' do
      it 'adds an initializer into the app containers initializers' do
        container = build_container
        allow(Appfuel).to receive(:default_app_name).with(no_args) { 'bar' }
        allow(Appfuel).to receive(:app_container).with(nil) { container }
        Initialize.define("global.foo") {}

        initializer = container['global.initializers.foo']
        expect(initializer).to be_an_instance_of(Initialize::Initializer)
        expect(initializer.name).to eq('foo')
      end

      it 'appends another initializer on to the first' do
        container = build_container
        allow(Appfuel).to receive(:default_app_name).with(no_args) { 'bar' }
        allow(Appfuel).to receive(:app_container).with(nil) { container }

        Initialize.define("global.foo",) {}
        Initialize.define("global.bar") {}

        expect(container['global.initializers.foo'].name).to eq('foo')
        expect(container['global.initializers.bar'].name).to eq('bar')
      end

      it 'adds a feature initializer' do
        container = build_container
        allow(Appfuel).to receive(:default_app_name).with(no_args) { 'bar' }
        allow(Appfuel).to receive(:app_container).with(nil) { container }
        Initialize.define("memberships.roles") {}

        initializer = container['features.memberships.initializers.roles']
        expect(initializer).to be_an_instance_of(Initialize::Initializer)
        expect(initializer.name).to eq('roles')
      end
    end


    context 'handle_configuration' do
      it 'populates the configuration and registers config and its env' do
        definition = double('some config definition')
        env        = {some: 'env vars'}
        overrides  = {some: 'cli overrides'}
        inputs     = {env: env, overrides: overrides}
        config     = {some: 'configs', env: 'dev'}
        container  = build_container(config_definition: definition)

        allow(definition).to receive(:populate).with(inputs) { config }

        Initialize.handle_configuration(container, inputs)
        expect(container[:config]).to eq(config)
        expect(container[:env]).to eq('dev')
      end

      it 'fails when no env is in the config' do
        definition = double('some config definition')
        env        = {some: 'env vars'}
        overrides  = {some: 'cli overrides'}
        inputs     = {env: env, overrides: overrides}
        config     = {some: 'configs'}
        container  = build_container(config_definition: definition)

        allow(definition).to receive(:populate).with(inputs) { config }

        msg = 'key (:env) is missing from config'
        expect {
          Initialize.handle_configuration(container, inputs)
        }.to raise_error(RuntimeError, msg)
      end
    end

    context 'handle_initializers' do
      it 'runs the only initializer' do
        inputs = {
          app_name: 'my_app',
          env: 'dev',
          config: {bar: 'with bar'}
        }

        container = build_container(inputs)
        allow(Appfuel).to receive(:default_app_name).with(no_args) { 'my_app' }
        allow(Appfuel).to receive(:app_container).with(nil) { container }
        Initialize.define('global.foo') do |configs, _container|
          _container.register(:foo, "foo has been initialized - #{configs[:bar]}")
        end

        container.register('global.initializers.run', ['foo'])


        Appfuel.run_initializers('global', container)
        expect(container[:foo]).to eq("foo has been initialized - with bar")
      end

      it 'skips initializer when env is not allowed' do
        inputs = {
          app_name: 'my_app',
          env: 'dev',
          config: {bar: 'with bar'}
        }

        container = build_container(inputs)
        allow(Appfuel).to receive(:default_app_name).with(no_args) { 'my_app' }
        allow(Appfuel).to receive(:app_container).with(nil) { container }
        Initialize.define('global.foo', 'qa') do |configs, _container|
          _container.register(:foo, "this will never happen")
        end

        container.register('global.initializers.run', ['foo'])

        initializer = container['global.initializers.foo']
        expect(initializer).not_to receive(:call)
        Appfuel.run_initializers('global', container)
      end

      it 'skips when initializer is excluded, exclude name is a symbol' do
        inputs = {
          app_name: 'my_app',
          env: 'dev',
          config: {bar: 'with bar'}
        }

        container = build_container(inputs)
        allow(Appfuel).to receive(:default_app_name).with(no_args) { 'my_app' }
        allow(Appfuel).to receive(:app_container).with(nil) { container }
        Initialize.define('global.foo') do |configs, _container|
          _container.register(:foo, "will never happen")
        end

        container.register('global.initializers.run', ['foo'])
        initializer = container['global.initializers.foo']

        expect(initializer).not_to receive(:call)
        Appfuel.run_initializers("global", container, [:foo])
      end

      it 'skips when initializer is excluded, exclude name is a string' do
        inputs = {
          app_name: 'my_app',
          env: 'dev',
          config: {bar: 'with bar'}
        }

        container = build_container(inputs)
        allow(Appfuel).to receive(:default_app_name).with(no_args) { 'my_app' }
        allow(Appfuel).to receive(:app_container).with(nil) { container }
        Initialize.define('global.foo') do |configs, _container|
          _container.register(:foo, "will never happen")
        end

        container.register('global.initializers.run', ['foo'])
        initializer = container['global.initializers.foo']

        expect(initializer).not_to receive(:call)
        Appfuel.run_initializers("global", container, ['foo'])
      end

      it 'fails when exlude is not an array' do
        msg = ':exclude must be an array'
        expect {
          container = build_container
          Appfuel.run_initializers("global", container, 'blah')
        }.to raise_error(ArgumentError, msg)
      end

      it 'handles raised errors' do
        inputs = {
          app_name: 'my_app',
          env: 'dev',
          config: {bar: 'with bar'}
        }

        container = build_container(inputs)
        allow(Appfuel).to receive(:default_app_name).with(no_args) { 'my_app' }
        allow(Appfuel).to receive(:app_container).with(nil) { container }
        Initialize.define('global.foo') do |configs, _container|
          fail "I am an error"
        end

        container.register('global.initializers.run', ['foo'])
        msg = '[Appfuel:my_app] Initialization FAILURE - I am an error'
        expect {
          Appfuel.run_initializers("global", container)
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '.run' do
      it 'handles configuration and initializers' do
        app_name  = 'foo'
        params    = {foo: 'bar'}
        container = build_container(repository_initializer: ->(c) {})
        allow(Appfuel).to receive(:default_app_name) { app_name }
        allow(Appfuel).to receive(:app_container).with(app_name) { container }

        expect(Initialize).to(
          receive(:handle_configuration).with(container, params)
        ) { container }

        expect(Appfuel).to(
          receive(:run_initializers).with('global', container, [])
        ) { container }

        result = Initialize.run(params)
        expect(result).to eq(container)
      end
    end

    def setup_container(env, config, initializers)
      inputs = {
        app_name: 'my_app',
        config: config,
        env: env
      }
      container = build_container(inputs)
      container.namespace('global') do
        register('initializers', [initializer])
      end
      container
    end
  end
end
