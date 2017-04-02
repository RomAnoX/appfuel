module Appfuel::ViewModel
  RSpec.describe Base do
    describe '#initialize' do
      it 'must pass in a model finder' do
        vm = Base.new('some finder')
        expect(vm.finder).to eq 'some finder'
      end
    end

    describe '#present' do
      it 'uses the finder to a get a view model to call' do
        finder = double('some finder')
        entity = double('some entity')
        inputs = {}
        model  = double('some view model')

        allow(finder).to receive(:call).with(entity, inputs) { model }
        expect(model).to receive(:call).with(entity, inputs)

        vm = Base.new(finder)
        vm.present(entity, inputs)
      end

      it 'returns the result of calling the view model' do
        finder = double('some finder')
        entity = double('some entity')
        inputs = {}
        model  = double('some view model')
        result = {foo: 'bar'}
        allow(finder).to receive(:call).with(entity, inputs) { model }
        allow(model).to receive(:call).with(entity, inputs) { result }

        vm = Base.new(finder)
        expect(vm.present(entity, inputs)).to eq result
      end
    end
  end
end
