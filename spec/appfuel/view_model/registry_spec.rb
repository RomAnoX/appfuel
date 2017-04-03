module Appfuel::ViewModel
  RSpec.describe Registry do
    context '.view_models' do
      it 'defaults to an empty hash' do
        registry = setup
        expect(registry.view_models).to eq({})
      end
    end

    context '.view_model?' do
      it 'returns false when the view model is not found' do
        registry = setup
        expect(registry.view_model?(:foo)).to be false
      end

      it 'returns true when a view model key exists' do
        registry = setup
        registry.view_models[:foo] = double('some view model')
        expect(registry.view_model?(:foo)).to be true
      end
    end

    context '.view_model_class' do
      it 'returns the base class' do
        expect(setup.view_model_class).to eq(Base)
      end
    end

    context '.view_model_finder' do
      it 'returns a lambda' do
        expect(setup.view_model_finder.lambda?).to be true
      end

      it 'delegates :find_view_model in the lambda' do
        registry = setup
        dataset  = 'this is some dataset'
        inputs   = {}
        results  = 'some view model results'

        expect(registry).to receive(:find_view_model).with(dataset, inputs) {
          results
        }
        finder   = registry.view_model_finder
        expect(finder.call(dataset, inputs)).to eq results
      end
    end

    context '.build_view_model' do
      it 'instantiates the view_model_class using the finder' do
        registry = setup
        klass  = registry.view_model_class
        finder = registry.view_model_finder
        expect(klass).to receive(:new).with(finder)
        registry.build_view_model
      end

      it 'returns the newly instantiated view model object' do
        registry = setup
        klass  = registry.view_model_class
        finder = registry.view_model_finder
        result = 'this is a newly create view model'
        allow(klass).to receive(:new).with(finder) { result }
        expect(registry.build_view_model).to eq result
      end
    end

    context '.default_view_name' do
      it 'returns false when the dataset does not implement :domain_basename' do
        dataset = double('some random data')
        expect(setup.default_view_name(dataset)).to be false
      end

      it 'returns the domain basename when dataset is an entity' do
        dataset = double('some random data')
        allow(dataset).to receive(:respond_to?).with(:domain_basename) { true }
        allow(dataset).to receive(:respond_to?).with(:collection?) { false }
        allow(dataset).to receive(:domain_basename).with(no_args) { 'foo' }
        expect(setup.default_view_name(dataset)).to eq :foo
      end

      it 'returns the domain basename ending with _collection' do
        dataset = double('some random data')
        allow(dataset).to receive(:respond_to?).with(:domain_basename) { true }
        allow(dataset).to receive(:respond_to?).with(:collection?) { true }
        allow(dataset).to receive(:domain_basename).with(no_args) { 'foo' }
        allow(dataset).to receive(:collection?).with(no_args) { true }

        expect(setup.default_view_name(dataset)).to eq :foo_collection
      end
    end

    context '.generic_view_model' do
      it 'creates a proc that calls :to_view_model on the dataset' do
        dataset = double('some random dataset')
        result  = { foo: 'bar' }
        allow(dataset).to receive(:respond_to?).with(:to_view_model) { true }
        expect(dataset).to receive(:public_send).with(:to_view_model) { result }

        response = setup.generic_view_model(dataset)
        expect(response.lambda?).to be true
        expect(response.call(dataset)).to eq result
      end

      it 'creates a proc that calls :to_h on the dataset' do
        dataset = double('some random dataset')
        result  = { foo: 'bar' }
        allow(dataset).to receive(:respond_to?).with(:to_view_model) { false }
        allow(dataset).to receive(:respond_to?).with(:to_h) { true }
        expect(dataset).to receive(:public_send).with(:to_h) { result }

        response = setup.generic_view_model(dataset)
        expect(response.lambda?).to be true
        expect(response.call(dataset)).to eq result
      end

      it 'creates a proc that calls :to_hash on the dataset' do
        dataset = double('some random dataset')
        result  = { foo: 'bar' }
        allow(dataset).to receive(:respond_to?).with(:to_view_model) { false }
        allow(dataset).to receive(:respond_to?).with(:to_h) { false }
        allow(dataset).to receive(:respond_to?).with(:to_hash) { true }
        expect(dataset).to receive(:public_send).with(:to_hash) { result }

        response = setup.generic_view_model(dataset)
        expect(response.lambda?).to be true
        expect(response.call(dataset)).to eq result
      end

      it 'creates a proc that calls :to_a on the dataset' do
        dataset = double('some random dataset')
        result  = ['a', 'b', 'c']
        allow(dataset).to receive(:respond_to?).with(:to_view_model) { false }
        allow(dataset).to receive(:respond_to?).with(:to_h) { false }
        allow(dataset).to receive(:respond_to?).with(:to_hash) { false }
        allow(dataset).to receive(:respond_to?).with(:to_a) { true }
        expect(dataset).to receive(:public_send).with(:to_a) { result }

        response = setup.generic_view_model(dataset)
        expect(response.lambda?).to be true
        expect(response.call(dataset)).to eq result
      end

      it 'creates a proc that calls :to_s on the dataset' do
        dataset = double('some random dataset')
        result  = 'some resulting string'
        allow(dataset).to receive(:respond_to?).with(:to_view_model) { false }
        allow(dataset).to receive(:respond_to?).with(:to_h) { false }
        allow(dataset).to receive(:respond_to?).with(:to_hash) { false }
        allow(dataset).to receive(:respond_to?).with(:to_a) { false }
        expect(dataset).to receive(:public_send).with(:to_s) { result }

        response = setup.generic_view_model(dataset)
        expect(response.lambda?).to be true
        expect(response.call(dataset)).to eq result
      end
    end

    context '.view_model_module' do
      it 'returns the root module when :global_view is true' do
        registry = setup
        dataset  = double('some dataset')
        inputs   = { global_view: true }
        root     = double('some root module')
        expect(registry).to receive(:root_module).with(no_args) { root }
        expect(registry.view_model_module(dataset, inputs)).to eq root
      end

      it 'returns the root module when datasets returns true for :global?' do
        registry = setup
        dataset  = double('some dataset')
        inputs   = {}
        root     = double('some root module')

        allow(dataset).to receive(:respond_to?).with(:global?) { true }
        allow(dataset).to receive(:global?).with(no_args) { true }
        expect(registry).to receive(:root_module).with(no_args) { root }
        expect(registry.view_model_module(dataset, inputs)).to eq root
      end


      it 'returns the registry when the dataset is not global' do
        registry = setup
        dataset  = double('some dataset')
        inputs   = {}

        allow(dataset).to receive(:respond_to?).with(:global?) { false }
        expect(registry.view_model_module(dataset, inputs)).to eq registry
      end
    end

    context '.find_view_model' do
      it 'returns a view model with a custom name' do
        registry = setup
        name     = :foo_bar
        dataset  = double('some dataset')
        inputs   = {view_name: name}
        model    = double('i am a view model')
        registry.view_models[name] = model

        expect(registry.find_view_model(dataset, inputs)).to eq model
      end

      it 'returns a view model with an entity name' do
        registry = setup
        name     = :my_entity
        entity   = double('some entity')
        model    = double('some viewmodel')

        allow(entity).to receive(:respond_to?).with(:global?) { true }
        allow(entity).to receive(:global?).with(no_args) { false }

        allow(entity).to receive(:respond_to?).with(:domain_basename) { true }
        allow(entity).to receive(:domain_basename).with(no_args) { name }

        allow(entity).to receive(:respond_to?).with(:collection?) { true }
        allow(entity).to receive(:collection?).with(no_args) { false }

        registry.view_models[name] = model
        expect(registry.find_view_model(entity)).to eq model
      end

      it 'returns the generic view model when name returns false' do
        registry = setup
        name     = :my_entity
        entity   = double('some entity')

        allow(entity).to receive(:respond_to?).with(:global?) { true }
        allow(entity).to receive(:global?).with(no_args) { false }

        allow(entity).to receive(:respond_to?).with(:domain_basename) { true }
        allow(entity).to receive(:domain_basename).with(no_args) { name }

        allow(entity).to receive(:respond_to?).with(:collection?) { true }
        allow(entity).to receive(:collection?).with(no_args) { false }

        # I have to do this because rspec is using respond_to on my double
        allow(entity).to receive(:respond_to?).at_least(:once)

        # we will not add the entity basename so that it won't be found
        # causing the generic view to be used instead
        expect(registry).to receive(:generic_view_model).with(entity) { 'blah' }
        expect(registry.find_view_model(entity)).to eq 'blah'
      end
    end

    describe '.present_view_model' do
      it 'returns the raw dataset when return_format is "raw"' do
        registry = setup
        inputs   = {return_format: 'raw'}
        dataset  = 'some dataset'

        expect(registry.present_view_model(dataset, inputs)).to eq dataset
      end

      it 'delegates to find view model and call that view model' do
        registry = setup
        inputs   = {}
        dataset  = 'some dataset'
        vm       = double('some view model')
        result   = 'some final view model result'
        expect(registry).to receive(:find_view_model).with(dataset, inputs) {
          vm
        }

        expect(vm).to receive(:call).with(dataset, inputs) { result }
        expect(registry.present_view_model(dataset, inputs)).to eq result
      end
    end

    describe '.view_model' do
      it 'fails when called without a block' do
        msg = 'view models must be added with a block'
        registry = setup
        expect {
          registry.view_model('foo')
        }.to raise_error(RuntimeError, msg)
      end

      it 'builds a view model with the view_model_class' do
        registry = setup
        expect(registry).to receive(:build_view_model).with(no_args)
        registry.view_model(:foo) {|dataset, inputs| dataset }
      end

      it 'adds a lamda with the key name' do
        registry = setup
        registry.view_model(:foo) {|dataset, inputs| dataset }
        expect(registry.view_models[:foo].lambda?).to be true
      end

      it 'uses the instantiated view model to call :instance_exec in the lambda' do
        registry = setup
        vm = double('i am a view model')

        dataset = 'some dataset'
        inputs  = {}

        allow(registry).to receive(:build_view_model).with(no_args) { vm }
        expect(vm).to receive(:instance_exec).with(dataset, inputs)

        registry.view_model(:foo) {|data, stuff| data }

        vm_lambda = registry.view_models[:foo]
        vm_lambda.call(dataset, inputs)
      end
    end

    def setup
      registry = Class.new do
        extend Appfuel::RootModule
        extend Registry
      end
      registry
    end
  end
end
