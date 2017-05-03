module Appfuel
  RSpec.describe Initialize do
    context '.define' do
      it 'adds an initializer into the app containers initializers' do
        list = []
        allow(Appfuel).to receive(:resolve).with("global.initializers", nil) {
          list
        }
        Initialize.define("global", "foo") {}
        expect(list.first).to be_an_instance_of(Initialize::Initializer)
      end

      it 'appends another initializer on to the first' do
        list = []
        list = []
        allow(Appfuel).to receive(:resolve).with("global.initializers", nil) {
          list
        }
        Initialize.define("global", "foo") {}
        Initialize.define("global", "bar") {}

        expect(list[0].name).to eq "foo"
        expect(list[1].name).to eq "bar"
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
        initializer = Initialize::Initializer.new(:foo) do |configs, container|
          container.register(:foo, "foo has been initialized - #{configs[:bar]}")
        end
        container = setup_container(initializer, 'dev', bar: 'with bar')

        Appfuel.run_initializers('global', container)
        expect(container[:foo]).to eq("foo has been initialized - with bar")
      end

      it 'skips initializer when env is not allowed' do
        initializer = Initialize::Initializer.new(:foo, :qa) do |configs, container|
          container.register("global", :foo)
        end
        container = setup_container(initializer, 'dev', bar: 'some config')
        expect(initializer).not_to receive(:call)
        Appfuel.run_initializers('global', container)
      end

      it 'skips when initializer is excluded, exclude name is a symbol' do
        initializer = Initialize::Initializer.new(:foo) do |configs, container|
          container.register(:foo, "bar")
        end
        container = setup_container(initializer, 'dev', bar: 'some config')
        expect(initializer).not_to receive(:call)
        Appfuel.run_initializers("global", container, [:foo])
      end

      it 'skips when initializer is excluded, exclude name is a string' do
        initializer = Initialize::Initializer.new(:foo) do |configs, container|
          container.register(:foo, "bar")
        end
        container = setup_container(initializer, 'dev', bar: 'some config')

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
        initializer = Initialize::Initializer.new(:foo) do |configs, container|
          fail "I am an error"
        end

        container = setup_container(initializer, 'dev', bar: 'some config')
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

    def setup_container(initializer, env, config)
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
