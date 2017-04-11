module Appfuel
  RSpec.describe Initialize do
    it 'adds an initializer into the app containers initializers' do
      list = []
      allow(Appfuel).to receive(:resolve).with(:initializers) { list }
      Initialize.define :foo do
        # some block of code
      end
      expect(list.first).to be_an_instance_of(Initialize::Initializer)
    end
  end
end
