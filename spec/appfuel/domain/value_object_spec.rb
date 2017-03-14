module Appfuel::Domain
  RSpec.describe ValueObject do
    it 'mixes in Dsl' do
      expect(ValueObject.ancestors).to include Dsl
    end

    it 'mixes in base instance behavior' do
      expect(ValueObject.ancestors).to include Base
    end

    it 'enables value object' do
      expect(ValueObject.value_object?).to be true
    end
  end
end
