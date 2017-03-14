module Appfuel
  RSpec.describe Validators do
    context '#validators' do
      it 'has no validators by default' do
        feature = setup
        expect(feature.validators).to eq({})
      end
    end

    context 'validator' do
      it 'assigns a custom validator' do
        validator = double('Somme Validator')
        allow(validator).to receive(:respond_to?).with(:call) { true }
        feature = setup
        feature.validator :foo, validator
        expect(feature.validators[:foo]).to eq validator
      end

      it 'fails when the validator does not implement :call' do
        validator = double('Somme Validator')
        feature = setup
        msg = 'validator :foo must implement call'
        expect {
          feature.validator :foo, validator
        }.to raise_error(RuntimeError, msg)
      end

      it 'creates a validator when a block is given' do
        feature = setup
        feature.validator :foo do
          required(:id).filled(:int?, gt?: 5)
        end
        expect(feature.validators[:foo]).to be_a(Dry::Validation::Schema)
      end

      it 'creates a form validator by default' do
        feature = setup
        feature.validator :foo do
          required(:id).filled(:int?, gt?: 5)
        end

        validator = feature.validators[:foo]
        result = validator.call({'id' => '6'})
        expect(result.success?).to be true
      end

      it 'creates a schema validator when given a schema type' do
        feature = setup
        feature.validator :foo, :schema do
          required(:id).filled(:int?, gt?: 5)
        end

        validator = feature.validators[:foo]
        result = validator.call({'id' => '6'})
        expect(result.failure?).to be true

        result = validator.call(id: 7)
        expect(result.success?).to be true
      end
    end

    context 'validator?' do
      it 'return false when there are no validators' do
        feature = setup
        expect(feature.validator?(:foo)).to be false
      end

      it 'returns true when a validator is assigned' do
        feature = setup
        validator = double('Somme Validator')
        allow(validator).to receive(:respond_to?).with(:call) { true }
        feature.validator :foo, validator
        expect(feature.validator?(:foo)).to be true
      end
    end

    def setup
      mod = Class.new do

        extend Validators

        def self.root_module
          self
        end

      end

      # build the dependency injection container and add the app_validator
      # to it
      container = build_container(app_validator: Dry::Validation::Schema)
      mod.class_eval do
        define_singleton_method(:container) do
          container
        end
      end

      mod
    end
  end
end
