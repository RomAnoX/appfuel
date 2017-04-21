module Appfuel::Validation
  RSpec.describe Appfuel::Validation do
    describe '#initialize' do
      it 'requires a name and a schema' do
        name = 'my_validator'
        schema = mock_schema

        validator = Validator.new(name, schema)
        expect(validator.name).to eq(name)
        expect(validator.schema).to eq(schema)
      end

      it 'defaults fail fast to false' do
        validator = Validator.new('my-name', mock_schema)
        expect(validator.fail_fast?).to be false
      end

      it 'fails when schema does not implement call' do
        schema = double('some schema')
        msg = 'schema must implement :call'
        expect {
          Validator.new('my-name', schema)
        }.to raise_error(ArgumentError, msg)
      end
    end

    context '#enable_fast_fail' do
      it 'toggles fail_fast to true' do
        validator = Validator.new('some-name', mock_schema)
        validator.enable_fail_fast
        expect(validator.fail_fast?).to be true
      end
    end

    context '#disable_fast_fail' do
      it 'toggles fail_fast to true' do
        validator = Validator.new('some-name', mock_schema)
        validator.enable_fail_fast
        validator.disable_fail_fast
        expect(validator.fail_fast?).to be false
      end
    end

    context '#pipe?' do
      it 'returns false beause it is not a pipe' do
        validator = Validator.new('some-name', mock_schema)
        expect(validator.pipe?).to be false
      end
    end

    context '#call' do
      it 'delegates to the dry schema' do
        schema = double('schema')
        inputs = {foo: 'bar'}

        expect(schema).to receive(:call).with(inputs)
        validator = Validator.new('some-name', schema)

        validator.call(inputs)
      end

      it 'returns the results from validating the inputs' do
        inputs = {foo: 'bar'}
        output = 'some validation output'
        schema = mock_schema(inputs, output)
        validator = Validator.new('some-name', schema)
        expect(validator.call(inputs)).to eq output
      end
    end

    def mock_schema(inputs = {}, output = {})
      schema = double('schema')
      allow(schema).to receive(:call).with(inputs) { output }
      schema
    end
  end
end
