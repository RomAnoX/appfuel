module Appfuel::Validation
  RSpec.describe '#initialize' do
    it 'requires a name and a schema' do
      name = 'my_validator'
      schema = double('some schema')
      allow(schema).to receive(:call)

      validator = Validator.new(name, schema)
      expect(validator.name).to eq(name)
      expect(validator.schema).to eq(schema)
    end

    it 'defaults fail fast to false' do
      name = 'my_validator'
      schema = double('some schema')
      allow(schema).to receive(:call)

      validator = Validator.new(name, schema)
      expect(validator.fail_fast?).to be false
    end

    it 'fails when schema does not implement call' do
      name = 'my_validator'
      schema = double('some schema')
      msg = 'schema must implement :call'
      expect {
        Validator.new(name, schema)
      }.to raise_error(ArgumentError, msg)
    end
  end
end
