module Appfuel
  RSpec.describe ValidatorDependency do
    context 'validator' do
      it 'fails when used with out a block and nothing assigned' do
        cmd = setup

        msg = 'first arg must be a symbol or respond to :call if no block is given'
        expect {
          cmd.validator
        }.to raise_error(RuntimeError, msg)
      end

      it 'assigns a validator declared in the features module' do
        cmd = setup
        feature = cmd.feature_module
        validator = feature.validator(:foo) {}

        expected = [{ validator: validator, fail_fast: false }]
        cmd.validator :foo
        expect(cmd.validators).to eq(expected)
      end

      it 'assigns a global validator using options :global flag' do
        cmd = setup
        top = cmd.root_module
        validator = top.validator(:foo) {}


        expected = [{ validator: validator, fail_fast: false }]
        cmd.validator :foo, global: true
        expect(cmd.validators).to eq(expected)
      end

      it 'fails when you try to assign :form as a validator name' do
        cmd = setup
        msg = ':form and :schema are reserved validator keys'
        expect {
          cmd.validator :form
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when you try to assign :schema as a validator name' do
        cmd = setup
        msg = ':form and :schema are reserved validator keys'
        expect {
          cmd.validator :schema
        }.to raise_error(RuntimeError, msg)
      end

      it 'assigns a custom validator that implements call' do
        validator = double('Some Validator')
        allow(validator).to receive(:respond_to?).with(:call) { true }

        cmd = setup
        cmd.validator validator

        expected = [{ validator: validator, fail_fast: false }]
        expect(cmd.validators).to eq expected
      end

      it 'assigns a proc in place of a validator' do
        callable = ->(input, data) {}

        cmd = setup
        cmd.validator callable
        expected = [{ validator: callable, fail_fast: false }]
        expect(cmd.validators).to eq expected
      end

      it 'fails when validator does not implement call or is not a symbol' do
        validator = double('Some Validator')
        cmd = setup
        msg = 'first arg must be a symbol or respond to :call if no block is given'
        expect {
          cmd.validator validator
        }.to raise_error(RuntimeError, msg)
      end

      it 'assigns a custom Dry::Validation schema when a block is given' do
        cmd = setup
        cmd.validator do
          required(:id).filled(:int?, gt?: 0)
        end

        expect(cmd.validators.first[:validator]).to be_a(Dry::Validation::Schema)
      end

      it 'defaults to a form schema when no type is given with block' do
        cmd = setup
        cmd.validator do
          required(:id).filled(:int?, gt?: 0)
        end
        expect(cmd.validators.first[:validator]).to be_a(Dry::Validation::Schema)
        result = cmd.validators.first[:validator].call({"id" => "1"})
        expect(result.success?).to be true
      end

      it 'assigns a strict schema when type is schema and block is given' do
        cmd = setup
        cmd.validator :schema do
          required(:id).filled(:int?, gt?: 0)
        end

        expected_validator = cmd.validators.first[:validator]
        expect(expected_validator).to be_a(Dry::Validation::Schema)

        result = expected_validator.call({"id" => "1"})
        expect(result.success?).to be false

        result = expected_validator.call({id: 1})
        expect(result.success?).to be true
      end
    end

    context 'validator?' do
      it 'returns true when a feature validator name is assigned' do
        cmd = setup
        cmd.validator ->(inputs, data) {}
        expect(cmd.validators?).to be true
      end

      it 'returns false when there are no validators' do
        cmd = setup
        expect(cmd.validators?).to be false
      end
    end

    context 'skip_validation?' do
      it 'returns true when skip_validation! is used' do
        cmd = setup
        cmd.skip_validation!
        expect(cmd.skip_validation?).to be true
      end

      it 'returns false by default' do
        cmd = setup
        expect(cmd.skip_validation?).to be false
      end
    end

    def setup
      cmd = Class.new do

        extend ValidatorDependency

        @root_module = Module.new do
          extend Validators

          # Allows the root module to handle global level responsiblities
          def self.root_module
            self
          end
        end

        @feature_module = Class.new do
          extend RootModule
          extend Validators
        end

        @feature_module.root_module = @root_module

        def self.root_module
          @root_module
        end

        def self.feature_module
          @feature_module
        end
      end

      # build the dependency injection container and add the app_validator
      # to it
      container = build_container(app_validator: Dry::Validation::Schema)
      cmd.root_module.class_eval do
        define_singleton_method(:container) do
          container
        end
      end

      cmd
    end
  end
end
