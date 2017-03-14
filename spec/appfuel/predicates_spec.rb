module Appfuel
  RSpec.describe Predicates do
    it 'validates a criteria type is valid' do
      schema = setup
      criteria = instance_double(Criteria)
      allow(criteria).to receive(:instance_of?).with(Criteria) { true }

      result = schema.call(foo: criteria)
      expect(result).to be_success
    end

    it 'fails when the input is not a criteria' do
      schema = setup
      criteria = 'this is not a criteria'

      result = schema.call(foo: criteria)
      expect(result).to be_failure
    end

    def setup
      Dry::Validation.Schema do
        configure do
          predicates Appfuel::Predicates
        end

        required(:foo).filled(:criteria?)
      end
    end
  end
end
