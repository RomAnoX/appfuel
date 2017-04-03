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
    def setup
      registry = Class.new do
        extend Appfuel::RootModule
        extend Registry
      end
      registry
    end
  end
end
