module Appfuel
  RSpec.describe DbEntityMapEntry do
    context '#initialize' do
      it 'fails when there is no domain' do
        msg = 'entity is required'
        expect {
          create_entry({})
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when there is no db_class' do
        msg = 'db_class is required'
        expect {
          create_entry(entity: 'foo')
        }.to raise_error(RuntimeError, msg)
      end


      it 'fails when there is no db_column' do
        msg = 'db_column is required'
        expect {
          create_entry(entity: 'foo', db_class: 'foo')
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when there is no entity_attr' do
        msg = 'entity_attr is required'
        expect {
          create_entry(entity: 'foo', db_class: 'foo', db_column: 'bar')
        }.to raise_error(RuntimeError, msg)
      end

      it 'assigns the entity' do
        entry = create_entry(default_map_data)
        expect(entry.entity).to eq(default_map_data[:entity])
      end

      it 'assigns the entity_attr' do
        entry = create_entry(default_map_data)
        expect(entry.entity_attr).to eq(default_map_data[:entity_attr])
      end

      it 'assigns the db_class' do
        entry = create_entry(default_map_data)
        expect(entry.db_class).to eq(default_map_data[:db_class])
      end

      it 'assigns the db_column' do
        entry = create_entry(default_map_data)
        expect(entry.db_column).to eq(default_map_data[:db_column])
      end

      it 'skip_to_entity is false by default' do
        entry = create_entry(default_map_data)
        expect(entry.skip_to_entity?).to be false
      end

      it 'enables skip_to_entity' do
        entry = create_entry(default_map_data.merge(skip_to_entity: true))
        expect(entry.skip_to_entity?).to be true
      end


      it 'skip_to_db is false by default' do
        entry = create_entry(default_map_data)
        expect(entry.skip_to_db?).to be false
      end

      it 'enables skip_to_entity' do
        entry = create_entry(default_map_data.merge(skip_to_db: true))
        expect(entry.skip_to_db?).to be true
      end


      it 'skip_all is false by default' do
        entry = create_entry(default_map_data)
        expect(entry.skip_all?).to be false
      end

      it 'enables skip_all' do
        entry = create_entry(default_map_data.merge(skip_all: true))
        expect(entry.skip_all?).to be true
      end

      it 'enables skip_to_entity when skip_all' do
        entry = create_entry(default_map_data.merge(skip_all: true))
        expect(entry.skip_to_entity?).to be true
      end

      it 'enables skip_to_db when skip_all' do
        entry = create_entry(default_map_data.merge(skip_all: true))
        expect(entry.skip_to_db?).to be true
      end
    end

    def default_map_data
      {
        entity: 'foo.bar',
        entity_attr: 'id',
        db_class: 'DbFooish',
        db_column: 'foo_id',
      }
    end

    def create_entry(data)
      DbEntityMapEntry.new(data)
    end
  end
end
