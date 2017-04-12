module Appfuel
  RSpec.describe Initialize do
    context '.define' do
      it 'adds an initializer into the app containers initializers' do
        list = []
        allow(Appfuel).to receive(:resolve).with(:initializers) { list }
        Initialize.define("foo") {}
        expect(list.first).to be_an_instance_of(Initialize::Initializer)
      end

      it 'appends another initializer on to the first' do
        list = []
        allow(Appfuel).to receive(:resolve).with(:initializers) { list }
        Initialize.define("foo") {}
        Initialize.define("bar") {}

        expect(list[0].name).to eq "foo"
        expect(list[1].name).to eq "bar"
      end
    end
  end

  context '.run' do
    it 'populates the configuration definition in the app container' do
      root = double('some root module')
      definition = Appfuel::Configuration.define :foo do
        defaults bar: 'bar',
                 baz: 'baz'
      end
      allow(root).to receive(:configuration_definition).with(no_args) { definition }
      allow(root).to receive(:load_initializers).with(no_args)

      params = {root: root, app_name: :foo}
      init = setup_init
      container = init.setup_appfuel(params)
    end

    def setup_init
      obj = Object.new
      obj.extend(Appfuel::Initialize::Setup)
      obj
    end
  end
end
