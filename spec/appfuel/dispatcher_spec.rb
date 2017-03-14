module Appfuel
  RSpec.describe Dispatcher do

    context '#dispatch no root module injected' do
      it 'fails when root module is not a module' do
        dispatcher = setup('Invalid Root module')
        request    = Request.new('foo/bar', {})
        msg = 'Root module must be a Module'
        expect {
          dispatcher.dispatch(request)
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when feature module is not defined' do
        root_module = class_double(Module)
        request     = Request.new('foo/bar', {})

        allow_root_module_to_be_a_module(root_module)
        allow_feature_for_request(request, 'Foo')

        dispatcher = setup(root_module)

        msg = "Feature (Foo) not found in #{root_module}"
        expect {
          dispatcher.dispatch(request)
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when action class is not defined' do
        root_module     = class_double(Module)
        feature_module = class_double(Module)
        request        = Request.new('foo/bar', {})

        allow_root_module_to_be_a_module(root_module)
        allow_feature_for_request(request, 'Foo')
        allow_action_for_request(request, 'Bar')

        allow_const_defined(root_module, 'Foo', true)
        allow_const_get(root_module, 'Foo', feature_module)
        allow_const_defined(feature_module, 'Bar', false)

        dispatcher = setup(root_module)
        msg = "Action (Bar) not found in #{feature_module}"
        expect {
          dispatcher.dispatch(request)
        }.to raise_error(RuntimeError, msg)
      end

      it 'runs an action with inputs from the request' do
        root_module     = class_double(Module)
        feature_module = class_double(Module)
        action_class   = class_double(Action)
        inputs         = {foo: 'bar'}
        request        = Request.new('foo/bar', inputs)
        result         = 'this is a result'

        allow(request).to receive(:inputs).with(no_args) { inputs }
        allow_root_module_to_be_a_module(root_module)
        allow_feature_for_request(request, 'Foo')
        allow_action_for_request(request, 'Bar')

        allow_const_defined(root_module, 'Foo', true)
        allow_const_get(root_module, 'Foo', feature_module)
        allow_const_defined(feature_module, 'Bar', true)
        allow_const_get(feature_module, 'Bar', action_class)

        allow(action_class).to receive(:run).with(inputs) { result }

        dispatcher = setup(root_module)
        expect(dispatcher.dispatch(request)).to eq(result)
      end
    end

    def allow_root_module_to_be_a_module(mod)
      allow(mod).to receive(:is_a?).with(Module) { true }
    end

    def allow_feature_for_request(request, name)
      allow(request).to receive(:feature).with(no_args) { name }
    end

    def allow_action_for_request(request, name)
      allow(request).to receive(:action).with(no_args) { name }

    end

    def setup(root_module)
      dispatcher = Object.new
      dispatcher.extend(Dispatcher)
      dispatcher.class_eval do
        define_method(:root_module) do
          root_module
        end
      end
      dispatcher
    end

  end
end
