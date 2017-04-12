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

    def setup
      obj = Object.new
      obj.extend(Setup)
      obj
    end
  end
end
