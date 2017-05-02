module Appfuel::Domain
  RSpec.describe ValueObject do
    it 'mixes in Dsl' do
      expect(ValueObject.ancestors).to include Entity
    end

    it 'enables value object' do
      expect(ValueObject.value_object?).to be true
    end
  end
end
