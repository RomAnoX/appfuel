module Appfuel::Repository
  RSpec.describe MappingDsl do
    before(:each) do
      setup(app_name: 'foo')
    end

    context '#initialize' do
      it 'creates an empty map' do
        dsl = create_dsl('global.foo', to: :db, model: 'bar')
        expect(dsl.entries).to eq([])
      end

      it 'assigns the entity name as a string' do
        dsl = create_dsl('membership.member', to: :db, model: 'bar')
        expect(dsl.domain_name).to eq 'membership.member'
      end

      it 'assigns the storage type as :db' do
        dsl = create_dsl('membership.member', to: :db, model: 'bar')
        expect(dsl.storage_type).to eq(:db)
      end

      it 'expands the db model key to a fully qualified container key' do
        dsl = create_dsl('membership.member', to: :db, model: 'member')
        expected_key = 'features.membership.db.member'
        expect(dsl.storage_key).to eq(expected_key)
      end

      it 'translates the global db model using the given key' do
        dsl = create_dsl('membership.member', to: :db, model: 'global.user')
        expected_key = 'global.db.user'
        expect(dsl.storage_key).to eq(expected_key)
      end

      it 'defaults the container name to the Appfuel.default_app_name' do
        dsl = create_dsl('membership.member', to: :db, model: 'global.user')
        # foo was assign in before block
        expect(dsl.container_name).to eq('foo')
      end

      it 'assigns a container name' do
        dsl = create_dsl(
          'membership.member',
          to: :db,
          model: 'global.user',
          container: 'other-container'
        )
        expect(dsl.container_name).to eq('other-container')
      end

      it 'assigns StorageMap as the default map_class' do
        dsl = create_dsl('membership.member', to: :db, model: 'global.user')
        expect(dsl.map_class).to eq(StorageMap)
      end

      it 'assigns an entry_class manually' do
        dsl = create_dsl(
          'membership.member',
          to: :db,
          model: 'global.user',
          map_class: 'SomeClass'
        )
        expect(dsl.map_class).to eq('SomeClass')
      end

      it 'ignores the context of the key' do
        dsl = create_dsl(
          'membership.member',
          to: :db,
          model: 'foo.bar.baz.db.bob',
          contextual_key: false
        )
        expected_key = 'foo.bar.baz.db.bob'
        expect(dsl.storage_key).to eq(expected_key)
      end

      it 'fails when the domain name is empty' do
        msg = 'entity name can not be empty'
        expect {
          create_dsl('', to: :db, model: 'global.user')
        }.to raise_error(msg)
      end

      it 'fails when the model key is empty' do
        expect {
          create_dsl('foo.bar', to: :db, model: '')
        }.to raise_error('db model key can not be empty')
      end
    end

    context '#map' do
      it 'maps storage attr to attributes as strings' do
        dsl = create_dsl('foo.bar',to: :db, model: 'bar')
        dsl.map 'bar_id', 'id'
        entry = {storage_attr: 'bar_id', domain_attr: 'id'}
        expect(dsl.entries).to eq([entry])
      end

      it 'maps creates the domain_attr as the storage_attr when missing' do
        dsl = create_dsl('foo.bar',to: :db, model: 'bar')
        dsl.map 'bar_id'
        entry = {storage_attr: 'bar_id', domain_attr: 'bar_id'}
        expect(dsl.entries).to eq([entry])
      end

      it 'maps a column that will be skip' do
        dsl = create_dsl('foo.bar',to: :db, model: 'bar')
        dsl.map 'bar_id', skip: true
        entry = {storage_attr: 'bar_id', domain_attr: 'bar_id', skip: true}
        expect(dsl.entries).to eq([entry])
      end
    end

    context '#create_storage_map' do
      it 'creates a storage map from the data it collects' do
        dsl = create_dsl('foo.bar',to: :db, model: 'bar')
        dsl.map 'id'
        map = dsl.create_storage_map
        expect(map).to be_an_instance_of(StorageMap)
        expect(map.entries).to eq(dsl.entries)
        expect(map.domain_name).to eq(dsl.domain_name)
        expect(map.storage_type).to eq(dsl.storage_type)
        expect(map.storage_key).to eq(dsl.storage_key)
        expect(map.container_name).to eq(dsl.container_name)
      end
    end

    def setup(app_name:, data: {})
      container = build_container(data)
      Appfuel.framework_container.register(:default_app_name, app_name)
      Appfuel.framework_container.register(app_name, container)
    end

    def create_dsl(domain_name, options = {})
      MappingDsl.new(domain_name, options)
    end
  end
end
