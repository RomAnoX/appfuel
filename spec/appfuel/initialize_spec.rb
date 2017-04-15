module Appfuel
  RSpec.describe Initialize do
    context '.define' do
      it 'adds an initializer into the app containers initializers' do
        list = []
        allow(Appfuel).to receive(:resolve).with('initializers', nil) { list }
        Initialize.define("foo") {}
        expect(list.first).to be_an_instance_of(Initialize::Initializer)
      end

      it 'appends another initializer on to the first' do
        list = []
        allow(Appfuel).to receive(:resolve).with('initializers', nil) { list }
        Initialize.define("foo") {}
        Initialize.define("bar") {}

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
        config = {bar: 'with bar'}
        env = 'development'
        initializer = Initialize::Initializer.new(:foo) do |configs, container|
          container.register(:foo, "foo has been initialized - #{configs[:bar]}")
        end
        inputs = {
          initializers: [initializer],
          config: config,
          env: env
        }
        container = build_container(inputs)

        Initialize.handle_initializers(container, 'my_app')
        expect(container[:foo]).to eq("foo has been initialized - with bar")
      end

      it 'skips initializer when env is not allowed' do
        config = {bar: 'with bar'}
        env = 'development'
        initializer = Initialize::Initializer.new(:foo, :qa) do |configs, container|
          container.register(:foo, "bar")
        end
        inputs = {
          initializers: [initializer],
          config: config,
          env: env
        }
        container = build_container(inputs)
        expect(initializer).not_to receive(:call)
        Initialize.handle_initializers(container, 'my_app')
      end
    end
  end
end
