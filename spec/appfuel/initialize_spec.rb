module Appfuel
  RSpec.describe Initialize do
    context '.define' do
      it 'adds an initializer into the app containers initializers' do
        list = []
        allow(Appfuel).to receive(:resolve).with('initializers', nil) { list }
        Initialize.define("foo") {}
        expect(list.first).to be_an_instance_of(Initialize::Initializer)
      end

      it 'appends another initializer on to the first' do
        list = []
        allow(Appfuel).to receive(:resolve).with('initializers', nil) { list }
        Initialize.define("foo") {}
        Initialize.define("bar") {}

        expect(list[0].name).to eq "foo"
        expect(list[1].name).to eq "bar"
      end
    end
  end

  context '.run' do
    it 'populates the configuration definition in the app container' do
      definition = Appfuel::Configuration.define :foo do
        defaults bar: 'bar',
                 baz: 'baz'
      end

      root = double('some root module')
      params = {
        root: root,
        app_name: :foo,
        root_path: 'foo/bar',
        config_definition: definition
      }
      init = setup_init
      init.setup_appfuel(params)
    end

    def setup_init
      obj = Object.new
      obj.extend(Appfuel::Initialize::Setup)
      obj
    end
  end
end
