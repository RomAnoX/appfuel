module Appfuel::Repository
  RSpec.describe MappingCollection do
    before(:each) do
      setup(app_name: 'foo')
    end

    context '#initialize' do
      it 'defaults to an empty has for the map' do
        collection = MappingCollection.new
        expect(collection.collection).to eq({})
      end

      it 'assigns a map manually' do
        map = {'foo.bar' => 'somme mapper'}
        collection = create_collection(map)
        expect(collection.collection).to eq(map)
      end

      it 'fails when map is not a hash' do
        msg = 'collection must be a hash'
        expect {
          create_collection('this is not right')
        }.to raise_error(msg)
      end
    end

    def setup(app_name:, data: {})
      container = build_container(data)
      Appfuel.framework_container.register(:default_app_name, app_name)
      Appfuel.framework_container.register(app_name, container)
    end

    def create_collection(map = {})
      MappingCollection.new(map)
    end
  end
end
