module Appfuel::Application
  RSpec.describe Root do
    context '#handle_default_app_name' do
      it 'assigns the default app name when default_app is true' do
        params = {
          default_app: true
        }
        init = setup
        framework_container = build_container
        app_container = build_container(root: 'foo')

        init.handle_app_name(params, app_container, framework_container)
        expect(framework_container[:default_app_name]).to eq('foo')
      end

      it 'assigns the default app name when appfuel does not have one' do
        # NOTE: we do not set the default_app flag
        init = setup

        params = {}
        framework_container = build_container
        app_container = build_container(root: 'bar')

        allow(Appfuel).to receive(:default_app?).with(no_args) { false }
        init.handle_app_name(params, app_container, framework_container)
        expect(framework_container[:default_app_name]).to eq('bar')
      end

      it 'assigns the default app name from root when none exists' do
        # NOTE: we do not set the default_app flag or app_name
        init = setup
        params = {}
        framework_container = build_container
        app_container = build_container(root: mock_root(name: "FooBar"))

        allow(Appfuel).to receive(:default_app?).with(no_args) { false }
        init.handle_app_name(params, app_container, framework_container)
        expect(framework_container[:default_app_name]).to eq("foo_bar")
      end

      it 'does not assign a default name when appfuel has one' do
        init = setup
        params = {}
        framework_container = build_container
        app_container = build_container(root: mock_root(name: "FooBar"))

        allow(Appfuel).to receive(:default_app?).with(no_args) { true }
        init.handle_app_name(params, app_container, framework_container)
        expect(framework_container.key?(:default_app_name)).to be false
      end

      it 'returns the app_name derived from the root module' do
        init = setup
        params = {}
        framework_container = build_container
        app_container = build_container(root: mock_root(name: 'bar'))

        allow(Appfuel).to receive(:default_app?).with(no_args) { false }
        app_name = init.handle_app_name(params, app_container, framework_container)
        expect(app_name).to eq('bar')
      end

      it 'returns the app_name derived from the root' do
        init = setup
        params = {}
        framework_container = build_container
        app_container = build_container(root: mock_root(name: 'FooBar'))

        allow(Appfuel).to receive(:default_app?).with(no_args) { false }
        app_name = init.handle_app_name(params, app_container, framework_container)
        expect(app_name).to eq("foo_bar")
      end
    end

    context '#build_app_container' do
      it 'creates a new container when one is not given' do
        init   = setup
        params = {
          root: mock_root,
          root_path: 'some/path',
        }
        result = init.build_app_container(params)
        expect(result).to be_an_instance_of(Dry::Container)
      end

      it 'adds the root module to the app container' do
        init   = setup
        params = {
          root: mock_root,
          root_path: 'some/path',
        }
        result = init.build_app_container(params)
        expect(result[:root]).to eq(params[:root])
      end

      it 'adds an empty initializers thread safe hash' do
        init   = setup
        params = {
          root: mock_root,
          root_path: 'some/path',
        }
        result = init.build_app_container(params)
        expect(result['global.initializers']).to be_an_instance_of(ThreadSafe::Array)
      end

      it 'adds a configuration definition if the root module responds' do
        init   = setup
        config = 'some configuration definition'
        params = {
          root: mock_root,
          root_path: 'some/path',
          config_definition: config
        }
        result = init.build_app_container(params)
        expect(result[:config_definition]).to eq(config)
      end

      it 'adds an empty hash in the namespace global.validators' do
        init   = setup
        params = {
          root: mock_root,
          root_path: 'some/path',
        }
        result = init.build_app_container(params)
        expect(result['global.validators']).to be_an_instance_of(Hash)
      end

      it 'adds an empty hash in the namespace global.entity_builders' do
        init   = setup
        params = {
          root: mock_root,
          root_path: 'some/path',
        }
        result = init.build_app_container(params)
        expect(result['global.domain_builders']).to be_an_instance_of(Hash)
      end

      it 'adds an empty hash in the namespace global.presenters' do
        init   = setup
        params = {
          root: mock_root,
          root_path: 'some/path',
        }
        result = init.build_app_container(params)
        expect(result['global.presenters']).to be_an_instance_of(Hash)
      end
    end

    context '#setup_appfuel' do
      it 'creates an app container with key from app_name' do
        root   = mock_root
        params = {root: root, app_name: :foo, root_path: 'some/path'}
        init   = setup

        result = init.setup_appfuel(params)
        expect(result).to be_an_instance_of(Dry::Container)
      end

      it 'creates an app container with a name derived from the root module' do
        root   = mock_root(name: 'FooBar')
        params = {root: root, root_path: 'some/path'}
        init   = setup

        init.setup_appfuel(params)
        result = Appfuel.framework_container[:foo_bar]
        expect(result).to be_an_instance_of(Dry::Container)
      end

      it 'adds an empty intializers thread safe array' do
        params = {root: mock_root, app_name: :foo, root_path: 'some/path'}
        init   = setup

        result = init.setup_appfuel(params)
        expect(result['global.initializers']).to be_an_instance_of(ThreadSafe::Array)
      end

      it 'fires of after_setup hook' do
        hook = double('i am a hook')

        app_container = build_container
        params = {
          root: mock_root,
          app_name: :foo,
          root_path: 'foo/bar',
          on_after_setup: hook,
          app_container: app_container
        }

        init = setup
        allow(hook).to receive(:respond_to?).with(:call) { true }
        expect(hook).to receive(:call).with(app_container)

        init.setup_appfuel(params)
      end

      it 'fails when no root module is given' do
        msg  = 'Root module (:root) is required'
        init = setup
        expect {
          init.setup_appfuel({})
        }.to raise_error(ArgumentError, msg)
      end

      it 'fails when no root path is given' do
        msg  = 'Root path (:root_path) is required'
        init = setup
        expect {
          init.setup_appfuel({root: mock_root})
        }.to raise_error(ArgumentError, msg)
      end

      it 'fails when after_setup hook does not implement call' do
        msg  = 'After setup hook (:after_setup) must implement :call, ' +
          'which takes the di container as its only arg'

        init = setup
        params = {
          root: mock_root,
          root_path: '/balh',
          on_after_setup: 'bad hook'
        }
        expect {
          init.setup_appfuel(params)
        }.to raise_error(ArgumentError, msg)
      end
    end

    context '#call' do

    end

    def mock_root(name: 'foo')
      root = double('some root')
      allow(root).to receive(:to_s).with(no_args) { name }
      root
    end

    def setup
      obj = Object.new
      obj.extend(Root)
      obj
    end
  end
end
