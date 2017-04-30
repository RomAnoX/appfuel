module Appfuel::Repository
  RSpec.describe Mapper do

    context '#initialize' do
      it 'initalizes with the container root name' do
        mapper = create_mapper('foo')
        expect(mapper.container_root_name).to eq('foo')
      end

      it 'allows you to manually load your own map' do
        map = {}
        mapper = create_mapper('foo', map)
        expect(mapper.map).to eq(map)
      end

      it 'fails when map is not a hash' do
        msg = 'repository mappings must be a hash'
        expect {
          create_mapper('foo', 'bar')
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#map' do
      it 'loads the map from the app container when none is given' do
        root = 'foo'
        map  = {}
        container = build_container(repository_mappings: map)
        expect(Appfuel).to receive(:app_container).with(root) { container }
        mapper = create_mapper(root)
        expect(mapper.map).to eq(map)
      end
    end

    context 'entity?' do
      it 'returns false when entity is not registered' do
        map = {}
        mapper = create_mapper('foo', map)

        expect(mapper.entity?('foo.bar')).to be false
      end

      it 'returns true when entity is registered' do
        map = {'foo.bar' => {}}
        mapper = create_mapper('foo', map)
        expect(mapper.entity?('foo.bar')).to be true
      end
    end

    context 'entity_attr?' do
      it 'returns false when entity is not registered' do
        map = {}
        mapper = create_mapper('my_root', map)
        expect(mapper.entity_attr?('foo.bar', 'id')).to be false
      end

      it 'returns false when entity exists but attr does not' do
        map = {'foo.bar' => {}}
        mapper = create_mapper('my_root', map)
        expect(mapper.entity_attr?('foo.bar', 'baz')).to be false
      end

      it 'returns true when entity exists and attr exists' do
        map = {'foo.bar' => {'id' => 'some entry'}}
        mapper = create_mapper('my_root', map)
        expect(mapper.entity_attr?('foo.bar', 'id')).to be true
      end
    end

    context 'find' do
      it 'finds an existing entry' do
        entry = 'some entry, object does not matter'
        map = {'foo.bar' => {'id' => entry}}
        mapper = create_mapper('my_root', map)
        expect(mapper.find('foo.bar', 'id')).to eq entry
      end

      it 'fails when entry does not exist' do
        map = {}
        mapper = create_mapper('my_root', map)
        msg = 'Entity (foo.bar) is not registered'
        expect {
          mapper.find('foo.bar', 'id')
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when attr does not exist' do
        map = {'foo.bar' => {}}
        mapper = create_mapper('my_root', map)
        msg = 'Entity (foo.bar) attr (baz) is not registered'
        expect {
          mapper.find('foo.bar', 'baz')
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '.each_entity_attr' do
      it 'yields each entry for a mapped domain entity' do

        entry1 = 'first entry, object does not matter'
        map = {
          'foo.bar' => {
            'attr_1' => entry1
          }
        }

        mapper = create_mapper('my_root', map)
        expect {|b|
          mapper.each_entity_attr('foo.bar', &b)
        }.to yield_with_args(entry1)
      end

      it 'yields two entries' do
        entry1 = 'first entry, object does not matter'
        entry2 = 'second entry, object does not matter'
        map = {
          'foo.bar' => {
            'attr_1' => entry1,
            'attr_2' => entry2
          }
        }

        mapper = create_mapper('my_root', map)

        expect {|b|
          mapper.each_entity_attr('foo.bar', &b)
        }.to yield_successive_args(entry1, entry2)
      end
    end

    context '.storage_attr_mapped?' do
      it 'returns false when the column is not mapped' do
        entry = instance_double(MappingEntry)
        allow(entry).to receive(:storage_attr).with(no_args) { 'not_baz' }
        map = {
          'foo.bar' => {
            'bif' => entry
          }
        }
        mapper = create_mapper('my_root', map)
        expect(mapper.storage_attr_mapped?('foo.bar', 'baz')).to be false
      end

      it 'returns true when the column is mapped' do
        entry = instance_double(MappingEntry)
        allow(entry).to receive(:storage_attr).with(no_args) { 'bar_id' }
        map = {
          'foo.bar' => {
            'bif' => entry
          }
        }
        mapper = create_mapper('my_root', map)
        expect(mapper.storage_attr_mapped?('foo.bar', 'bar_id')).to be true
      end

      it 'fails when entity is not mapped' do
        msg = 'Entity (foo.bar) is not registered'
        mapper = create_mapper('my_root', {})
        expect {
          mapper.storage_attr_mapped?('foo.bar', 'bar_id')
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#storage_attr' do
      it 'fails when entity is not mapped' do
        msg = 'Entity (foo.bar) is not registered'
        mapper = create_mapper('my_root', {})
        expect {
          mapper.storage_attr('foo.bar', 'id')
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when the entity attribute is not mapped' do
        map = {'foo.bar' => {}}
        mapper = create_mapper('my_root', map)
        msg = 'Entity (foo.bar) attr (baz) is not registered'
        expect {
          mapper.storage_attr('foo.bar', 'baz')
        }.to raise_error(RuntimeError, msg)
      end

      it 'returns the attribute value mapped' do
        entry = instance_double(MappingEntry)
        attr_value = 'some value'
        allow(entry).to receive(:storage_attr).with(no_args) { attr_value }
        map = {
          'foo.bar' => {
            'bif' => entry
          }
        }
        mapper = create_mapper('my_root', map)
        expect(mapper.storage_attr('foo.bar', 'bif')).to eq(attr_value)
      end

    end
    def default_entry_data(data = {})
      default = {
        domain: 'foo.bar',
        domain_attr: 'id',
        storage_class: {db: 'bar'},
        storage_attr: 'bar_id'
      }

      default.merge(data)
    end

    def create_entry(data)
      MappingEntry.new(data)
    end

    def create_mapper(root_name, map = nil)
      Mapper.new(root_name, map)
    end
  end
end
