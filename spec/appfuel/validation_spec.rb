module Appfuel
  RSpec.describe Validation do
    context '.create_dry_validator' do
      it 'fails when an invalid type is given' do
        msg = "validator type must 'form' or 'schema' (foo) given"
        expect {
          Validation.create_dry_validator('foo')
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when no block is given' do
        msg = 'block is required to build a validator'
        expect {
          Validation.create_dry_validator('schema')
        }.to raise_error(RuntimeError, msg)
      end

      it 'creates a dry validator schema' do
        schema = Validation.create_dry_validator('schema') {}
        expect(schema.class).to be < Dry::Validation::Schema
      end

      it 'create a dry validator form' do
        schema = Validation.create_dry_validator('form') {}
        expect(schema.class).to be < Dry::Validation::Schema::Form
      end
    end

    context '.build_validator ' do
      it 'builds a new validator with a dry validator default type of form' do
        dry_validator = double('validator')
        allow(dry_validator).to receive(:call)

        expect(Validation).to receive(:create_dry_validator).with('form') {
          dry_validator
        }

        validator = Validation.build_validator('foo')
        expect(validator).to be_an_instance_of(Validation::Validator)
        expect(validator.schema).to eq(dry_validator)
      end

      it 'builds a new validator with dry validator schema' do
        dry_validator = double('validator')
        allow(dry_validator).to receive(:call)

        expect(Validation).to receive(:create_dry_validator).with('schema') {
          dry_validator
        }

        validator = Validation.build_validator('foo', type: 'schema')
        expect(validator).to be_an_instance_of(Validation::Validator)
      end

      it 'builds a new validator with default fail_fast as false' do
        dry_validator = double('validator')
        allow(dry_validator).to receive(:call)

        allow(Validation).to receive(:create_dry_validator).with('form') {
          dry_validator
        }

        validator = Validation.build_validator('foo')
        expect(validator.fail_fast?).to be false
      end

      it 'builds a new validator with fail_fast as true' do
        dry_validator = double('validator')
        allow(dry_validator).to receive(:call)

        allow(Validation).to receive(:create_dry_validator).with('form') {
          dry_validator
        }

        validator = Validation.build_validator('foo', fail_fast: true)
        expect(validator.fail_fast?).to be true
      end

      it 'builds a new validator with the correct name' do
        dry_validator = double('validator')
        allow(dry_validator).to receive(:call)

        allow(Validation).to receive(:create_dry_validator).with('form') {
          dry_validator
        }

        validator = Validation.build_validator('foo', fail_fast: true)
        expect(validator.name).to eq('foo')
      end
    end

    context '.define' do
      it 'defines feature validator and adds it to the container' do
        container = build_container
        allow(Appfuel).to receive(:app_container).with(no_args) { container }

        Validation.define('auth.foo') do
          required(:foo).filled(:str?)
        end

        validator = container['features.auth.validators.foo']
        expect(validator).to be_an_instance_of(Validation::Validator)
      end

      it 'defines a global validator and adds it to the container' do
        container = build_container
        allow(Appfuel).to receive(:app_container).with(no_args) { container }

        Validation.define('global.foo') do
          required(:foo).filled(:str?)
        end

        validator = container['global.validators.foo']
        expect(validator).to be_an_instance_of(Validation::Validator)
      end
    end
  end
end
