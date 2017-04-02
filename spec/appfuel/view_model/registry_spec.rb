module Appfuel::ViewModel
  RSpec.describe Registry do
    context '.view_models' do
      it 'defaults to an empty hash' do
        registry = setup
        expect(registry.view_models).to eq({})
      end
    end

    context '.view_model_class' do
      it 'returns the base class' do
        expect(setup.view_model_class).to eq(Base)
      end
    end

    def setup
      registry = Class.new do
        extend Appfuel::RootModule
        extend Registry
      end
      registry
    end
  end
end
