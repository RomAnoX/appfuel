module Appfuel
  RSpec.describe DbMappingRegistry do

    before(:each) do
      DbMappingRegistry.map = {}
    end

    it 'creates a dry container for a map by default' do
      expect(DbMappingRegistry.map).to be_an(Hash)
    end

    context '.<<' do
      it 'adds a map entry' do
        entry = create_entry(default_entry_data)
        registry << entry
        expected = { entry.entity_attr => entry }
        expect(registry.map[entry.entity]).to eq(expected)
      end

      it 'fails when entry is not a DbEntityMapEntry' do
        msg = "this registry only accepts Appfuel::DbEntityMapEntry objects"
        expect {
          registry << 'foo'
        }.to raise_error(RuntimeError, msg)
      end
    end

    context 'find' do
      it 'finds an existing entry' do
        entry = create_entry(default_entry_data)
        registry << entry
        expect(registry.find('foo.bar', 'id')).to eq entry
      end

      it 'fails when entry does not exist' do
        msg = 'Entity (foo.bar) is not registered'
        expect {
          registry.find('foo.bar', 'id')
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when attr does not exist' do
        entry = create_entry(default_entry_data)
        registry << entry
        msg = 'Entity (foo.bar) attr (baz) is not registered'
        expect {
          registry.find('foo.bar', 'baz')
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '.each_entity_attr' do
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

    context 'entity?' do
      it 'returns false when entity is not registered' do
        expect(registry.entity?('foo.bar')).to be false
      end

      it 'returns true when entity is registered' do
        entry = create_entry(default_entry_data)
        registry << entry
        expect(registry.entity?(entry.entity)).to be true
      end
    end

    context 'entity_attr?' do
      it 'returns false when entity is not registered' do
        expect(registry.entity_attr?('foo.bar', 'id')).to be false
      end

      it 'returns false when entity exists but attr does not' do
        entry = create_entry(default_entry_data)
        registry << entry
        expect(registry.entity_attr?('foo.bar', 'baz')).to be false
      end

      it 'returns true when entity exists and attr exists' do
        entry = create_entry(default_entry_data)
        registry << entry
        expect(registry.entity_attr?('foo.bar', 'id')).to be true
      end
    end
    def default_entry_data
      {
        entity: 'foo.bar',
        entity_attr: 'id',
        db_class: 'bar',
        db_column: 'bar_id'
      }
    end

    def registry
      DbMappingRegistry
    end

    def create_entry(data)
      DbEntityMapEntry.new(data)
    end
  end
end
