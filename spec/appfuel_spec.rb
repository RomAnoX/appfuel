RSpec.describe Appfuel do
  context '.framework_container' do
    it 'assigns Dry::Container by default' do
      expect(Appfuel.framework_container).to be_an_instance_of(Dry::Container)
    end
  end

  context '.framework_container=' do
    it 'will assign a default container' do
      # NOTE: there is no check for interface
      Appfuel.framework_container = 'foo'
      expect(Appfuel.framework_container).to eq 'foo'
    end
  end

  context '.default_app?' do
    it 'returns false when :default_app_name is not registered' do
      expect(Appfuel.default_app?).to be false
    end

    it 'returns false when default_app_name exists but no container' do
      Appfuel.framework_container.register(:default_app_name, :foo)
      expect(Appfuel.default_app?).to be false
    end

    it 'returns true when a default_app_name exists and app is registered' do
      Appfuel.framework_container.register(:default_app_name, :foo)
      Appfuel.framework_container.register(:foo, 'this is a container')
      expect(Appfuel.default_app?).to be true
    end
  end

  context '.default_app_name' do
    it 'fails when no default_app_name has been registered' do
      msg = 'Nothing registered with the key :default_app_name'
      expect {
        Appfuel.default_app_name
      }.to raise_error(Dry::Container::Error, msg)
    end

    it 'returns the default_app_name' do
      Appfuel.framework_container.register(:default_app_name, :foo)
      expect(Appfuel.default_app_name).to eq(:foo)
    end
  end

  context '.app_container' do
    it 'fails when name is not registered' do
      msg = 'Nothing registered with the key :foo'
      expect {
        Appfuel.app_container(:foo)
      }.to raise_error(Dry::Container::Error, msg)
    end

    it 'fails when :default_app_name is not registered and name is nil' do
      msg = 'Nothing registered with the key :default_app_name'
      expect {
        Appfuel.app_container
      }.to raise_error(Dry::Container::Error, msg)
    end

    it 'returns the app container registered with name' do
      Appfuel.framework_container.register(:some_app, 'this is a container')
      expect(Appfuel.app_container(:some_app)).to eq('this is a container')
    end

    it 'returns the default app when its registered' do
      Appfuel.framework_container.register(:default_app_name, :foo)
      Appfuel.framework_container.register(:foo, 'default_app_container')
      expect(Appfuel.app_container).to eq('default_app_container')
    end
  end

  context 'resolve' do
    it 'fails when app container does not respond to resolve' do
      Appfuel.framework_container.register(:some_app, 'this is a container')
      msg = 'Application container (some_app) does not implement :resolve'
      expect {
        Appfuel.resolve('foo', :some_app)
      }.to raise_error(RuntimeError, msg)
    end

    it 'resolves an item out of the app container' do
      container = build_container(foo: 'bar')
      Appfuel.framework_container.register(:some_app, container)
      expect(Appfuel.resolve(:foo, :some_app)).to eq('bar')
    end

    it 'resolve from the default app container' do
      container = build_container(fiz: 'biz')
      Appfuel.framework_container.register(:default_app_name, :foo)
      Appfuel.framework_container.register(:foo, container)
      expect(Appfuel.resolve(:fiz)).to eq('biz')
    end
  end

  context 'register' do
    it 'fails when app container does not respond to register' do
      Appfuel.framework_container.register(:some_app, 'this is a container')
      msg = 'Application container (some_app) does not implement :register'
      expect {
        Appfuel.register('foo', 'bar', :some_app)
      }.to raise_error(RuntimeError, msg)
    end

    it 'register an item into the app container' do
      container = build_container
      Appfuel.framework_container.register(:some_app, container)
      Appfuel.register(:foo, 'bar', :some_app)
      expect(container[:foo]).to eq('bar')
    end

    it 'register into the default app container' do
      container = build_container
      Appfuel.framework_container.register(:default_app_name, :foo)
      Appfuel.framework_container.register(:foo, container)
      Appfuel.register(:fiz, 'buzz')
      expect(container[:fiz]).to eq('buzz')
    end
  end
end
