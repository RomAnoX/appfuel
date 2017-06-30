module Appfuel::Repository
  RSpec.describe Mapper do

    context '#initialize' do
      it 'initalizes with the container root name' do
        mapper = create_mapper('foo')
        expect(mapper.container_root_name).to eq('foo')
      end

      it 'allows you to manually load your own map' do
        map = MappingCollection.new
        mapper = create_mapper('foo', map)
        expect(mapper.map).to eq(map)
      end

      it 'fails when map is not a hash' do
        msg = 'repository mappings must be a MappingCollection'
        expect {
          create_mapper('foo', 'bar')
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#map' do
      it 'loads the map from the app container when none is given' do
        root = 'foo'
        map = MappingCollection.new
        container = build_container(repository_mappings: map)
        expect(Appfuel).to receive(:app_container).with(root) { container }
        mapper = Mapper.new(root)
        expect(mapper.map).to eq(map)
      end
    end

    context 'entity?' do
      it 'returns false when entity is not registered' do
        mapper = create_mapper('foo')

        expect(mapper.entity?('foo.bar')).to be false
      end

      it 'returns true when entity is registered' do
        map = instance_double(MappingCollection)
        allow(map).to receive(:instance_of?).with(MappingCollection) { true }
        allow(map).to receive(:entity?).with('foo.bar') { true }

        mapper = create_mapper('foo', map)
        expect(mapper.entity?('foo.bar')).to be true
      end
    end

    xcontext '#undefined?' do
      it 'returns true when the value given is Types::Undefined' do
        value  = Types::Undefined
        mapper = create_mapper('foo')
        expect(mapper.undefined?(value)).to be(true)
      end

      it 'returns false when the value given is not Types::Undefined' do
        value  = 'some value'
        mapper = create_mapper('foo')
        expect(mapper.undefined?(value)).to be(false)
      end
    end

    context '#resolve_entity_value' do
      it 'gets the top level attribute of the domain' do
        value = 123456
        domain = Object.new
        domain.define_singleton_method(:id) do
          value
        end
        domain_attr = 'id'

        mapper = create_mapper('foo')
        expect(mapper.resolve_entity_value(domain, domain_attr)).to eq(value)
      end

      it 'traverses nested objects to get the value' do
        value = 123456
        role = Object.new
        role.define_singleton_method(:id) do
          value
        end
        user = Object.new
        user.define_singleton_method(:role) do
          role
        end
        member = Object.new
        member.define_singleton_method(:user) do
          user
        end
        group = Object.new
        group.define_singleton_method(:member) do
          member
        end
        domain = Object.new
        domain.define_singleton_method(:group) do
          group
        end
        domain_attr = 'group.member.user.role.id'

        mapper = create_mapper('foo')
        expect(mapper.resolve_entity_value(domain, domain_attr)).to eq(value)
      end
    end

    context '#create_entity_hash' do
      it 'creates a basic hash for a non nested attribute' do
        domain_attr = 'id'
        value  = 12345
        hash   = {'id' => value}
        mapper = create_mapper('foo')
        expect(mapper.create_entity_hash(domain_attr, value)).to eq(hash)
      end

      it 'creates a nested hash for an attribute with objects' do
        domain_attr = 'group.member.user.role.id'
        value = 12345
        hash  = {
          'group' => {
            'member' => {
              'user' => {
                'role' => {
                  'id' => value
                }
              }
            }
          }
        }
        mapper = create_mapper('foo')
        expect(mapper.create_entity_hash(domain_attr, value)).to eq(hash)
      end
    end

    context '#entity_value' do
      it 'resolves the entity value' do
        domain = double('some domain')
        domain_attr = 'foo.bar.baz.id'
        entry  = instance_double(MappingEntry)
        value  = 123
        mapper = create_mapper('foo')
        expect(mapper).to(
          receive(:resolve_entity_value).with(domain, domain_attr) { value }
        )
        allow(entry).to receive(:computed_attr?).with(no_args) { false }
        allow(entry).to receive(:domain_attr).with(no_args) { domain_attr }
        expect(mapper.entity_value(domain, entry)).to eq(value)
      end

      it 'resolves the entity value' do
        domain = double('some domain')
        domain_attr = 'foo.bar.baz.id'
        entry    = instance_double(MappingEntry)
        value    = 123
        computed = 'my computed value'
        mapper   = create_mapper('foo')
        expect(mapper).to(
          receive(:resolve_entity_value).with(domain, domain_attr) { value }
        )
        allow(entry).to receive(:domain_attr).with(no_args) { domain_attr }
        allow(entry).to receive(:computed_attr?).with(no_args) { true }
        allow(entry).to receive(:computed_attr).with(value, domain) { computed }
        expect(mapper.entity_value(domain, entry)).to eq(computed)
      end
    end

    context 'update_entity_hash' do
      it 'adds a single key value pair when domain attr does not contain "."' do
        hash   = {}
        value  = 123
        attr   = 'id'
        mapper = create_mapper('foo')
        mapper.update_entity_hash(attr, value, hash)
        expect(hash).to eq({attr => value})
      end

      it 'adds a nested hash when domain attr container "."' do
        hash   = {}
        value  = 123
        attr   = 'foo.bar.baz.id'
        mapper = create_mapper('foo')
        result = {'foo' => { 'bar' => {'baz' => { 'id' => value } } } }
        mapper.update_entity_hash(attr, value, hash)
        expect(hash).to eq(result)
      end
    end

    xcontext 'to_entity_hash' do
      it 'converts a storage hash into a mapped entity hash' do
        mapping1 = {
          domain_name: 'foo.bar',
          domain_attr: 'id',
          storage: {db: 'some class object'},
          storage_attr: 'bar_id'
        }
        mapping2 = {
          domain_name: 'foo.bar',
          domain_attr: 'data.code',
          storage: {db: 'some class object'},
          storage_attr: 'bar_code'
        }

        map = {
          'foo.bar' => {
            'id' => create_entry(mapping1),
            'data.code' => create_entry(mapping2)
          }
        }

        mapper  = create_mapper('myapp', map)
        data    = { 'bar_id'   => 123, 'bar_code' => 'abc' }
        mapper.define_singleton_method(:storage_hash) do |_storage|
          data
        end
        storage = double('some storage object')

        hash = { 'id' => 123, 'data' => {'code' => 'abc' }}
        expect(mapper.to_entity_hash('foo.bar', storage)).to eq(hash)
      end
    end


    xcontext '#to_storage' do
      it 'converts domain into a storage hash' do
        domain_name = 'foo.bar'
        db_key = 'global.db.user'
        mapping1 = {
          domain_name: domain_name,
          domain_attr: 'id',
          storage: {db: db_key},
          storage_attr: 'bar_id'
        }
        mapping2 = {
          domain_name: domain_name,
          domain_attr: 'data.code',
          storage: {db: db_key},
          storage_attr: 'bar_code'
        }

        id   = 123
        code = 'abc'
        data = Object.new
        data.define_singleton_method(:code) do
          code
        end

        domain = Object.new
        domain.define_singleton_method(:id) do
          id
        end

        domain.define_singleton_method(:data) do
          data
        end

        domain.define_singleton_method(:domain_name) do
          domain_name
        end

        map = {
          'foo.bar' => {
            'id' => create_entry(mapping1),
            'data.code' => create_entry(mapping2)
          }
        }

        mapper = create_mapper('myapp', map)
        result = {
          'global.db.user' => {
            'bar_id' => id,
            'bar_code' => code
          }
        }
        expect(mapper.to_storage(domain, :db)).to eq(result)
      end
    end

    def create_entry(data)
      MappingEntry.new(data)
    end

    def create_mapper(root_name, map = MappingCollection.new)
      Mapper.new(root_name, map)
    end
  end
end
