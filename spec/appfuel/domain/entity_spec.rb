module Appfuel::Domain
  RSpec.describe Entity do
    it 'mixes in Dsl' do
      expect(Entity.ancestors).to include Dsl
    end

    it 'mixes in base instance behavior' do
      expect(Entity.ancestors).to include Base
    end


    it 'disables value object' do
      expect(Entity.value_object?).to be false
    end
  end
end
