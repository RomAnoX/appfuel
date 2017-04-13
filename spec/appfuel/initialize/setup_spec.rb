module Appfuel::Initialize
  RSpec.describe Setup do
    context '#handle_default_app_name' do
      it 'assigns the default app name when default_app is true' do
        params    = {app_name: 'foo', default_app: true}
        root      = double('some root module')
        container = build_container
        init      = setup

        init.handle_app_name(root, params, container)
        expect(container[:default_app_name]).to eq(params[:app_name])
      end

      it 'assigns the default app name when appfuel does not have one' do
        # NOTE: we do not set the default_app flag
        params    = {app_name: 'bar'}
        root      = double('some root module')
        container = build_container
        init      = setup
        allow(Appfuel).to receive(:default_app?).with(no_args) { false }
        init.handle_app_name(root, params, container)
        expect(container[:default_app_name]).to eq(params[:app_name])
      end

      it 'assigns the default app name from root when none exists' do
        # NOTE: we do not set the default_app flag or app_name
        params    = {}
        root_name = "FooBar"
        root      = double('some root module')
        container = build_container
        init      = setup

        allow(Appfuel).to receive(:default_app?).with(no_args) { false }
        allow(root).to receive(:to_s).with(no_args) { root_name }
        init.handle_app_name(root, params, container)
        expect(container[:default_app_name]).to eq("foo_bar")
      end

      it 'does not assign a default name when appfuel has one' do
        params    = {}
        root_name = "FooBar"
        root      = double('some root module')
        container = build_container
        init      = setup

        allow(Appfuel).to receive(:default_app?).with(no_args) { true }
        allow(root).to receive(:to_s).with(no_args) { root_name }
        init.handle_app_name(root, params, container)
        expect(container.key?(:default_app_name)).to be false
      end

      it 'returns the app_name passed into params' do
        params    = {app_name: 'bar'}
        root      = double('some root module')
        container = build_container
        init      = setup
        allow(Appfuel).to receive(:default_app?).with(no_args) { false }
        app_name = init.handle_app_name(root, params, container)
        expect(app_name).to eq(params[:app_name])
      end

      it 'returns the app_name derived from the root' do
        params    = {}
        root_name = "FooBar"
        root      = double('some root module')
        container = build_container
        init      = setup

        allow(Appfuel).to receive(:default_app?).with(no_args) { false }
        allow(root).to receive(:to_s).with(no_args) { root_name }
        app_name = init.handle_app_name(root, params, container)
        expect(app_name).to eq("foo_bar")
      end
    end

    context '#build_app_container' do
      it 'creates a new container when one is not given' do
        root = double('some root module')
        init = setup
        result = init.build_app_container(root)
        expect(result).to be_an_instance_of(Dry::Container)
      end

      it 'adds the root module to the app container' do
        root = double('some root module')
        init = setup
        result = init.build_app_container(root)
        expect(result[:root]).to eq(root)
      end

      it 'adds an empty initializers thread safe hash' do
        root = double('some root module')
        init = setup
        result = init.build_app_container(root)
        expect(result[:initializers]).to be_an_instance_of(ThreadSafe::Array)
      end

      it 'adds a configuration definition if the root module responds' do
        root   = double('some root module')
        init   = setup
        config = 'some configuration definition'
        allow(root).to receive(:configuration_definition).with(no_args) { config }
        result = init.build_app_container(root)
        expect(result[:config_definition]).to eq(config)
      end
    end

    context '#setup_appfuel' do
      it 'creates an application container with key from app_name' do
        root   = double('some root module')
        params = {root: root, app_name: :foo}
        init   = setup
        allow(root).to receive(:load_initializers).with(no_args)

        result = init.setup_appfuel(params)
        expect(result).to be_an_instance_of(Dry::Container)
      end
    end

    def setup
      obj = Object.new
      obj.extend(Setup)
      obj
    end
  end
end
