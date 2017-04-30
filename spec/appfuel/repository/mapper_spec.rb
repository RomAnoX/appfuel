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

    xcontext '.each_entity_attr' do
      it 'yields the each entry' do
        entry = create_entry(default_entry_data)
        registry << entry

        expect {|b|
          registry.each_entity_attr('foo.bar', &b)
        }.to yield_with_args entry.entity_attr, entry
      end

      it 'yields two entries' do
        entry2_data = default_entry_data
        entry2_data[:entity_attr] = 'baz'
        entry2_data[:db_column] = 'baz_id'

        entry1 = create_entry(default_entry_data)
        entry2 = create_entry(entry2_data)

        registry << entry1
        registry << entry2

        expect {|b|
          registry.each_entity_attr('foo.bar', &b)
        }.to yield_successive_args(
              [entry1.entity_attr, entry1],
              [entry2.entity_attr, entry2])
      end
    end

    xcontext '.column_mapped?' do
      it 'returns false when the column is not mapped' do
        entry = create_entry(default_entry_data)
        registry << entry
        expect(registry.column_mapped?('foo.bar', 'baz')).to be false
      end

      it 'returns true when the column is mapped' do
        entry = create_entry(default_entry_data)
        registry << entry
        expect(registry.column_mapped?('foo.bar', 'bar_id')).to be true
      end

      it 'fails when entity is not mapped' do
        msg = 'Entity (foo.bar) is not registered'
        expect {
          registry.column_mapped?('foo.bar', 'bar_id')
        }.to raise_error(RuntimeError, msg)
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
