module Appfuel
  RSpec.describe DbEntityMapDsl do
    context '#initialize' do
      it 'creates an empty map' do
        expect(create_dsl('foo', 'bar').map_data).to eq([])
      end

      it 'assigns the entity name as a string' do
        expect(create_dsl('foo', 'bar').entity_name).to eq 'foo'
      end

      it 'assigns the db name as a string' do
        expect(create_dsl('foo', 'bar').db_name).to eq 'bar'
      end

      it 'fails when db name is empty' do
        msg = 'db_name can not be empty'
        expect {
          create_dsl("foo", '')
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#map' do
      it 'maps column to attributes as strings' do
        dsl = create_dsl('foo', 'bar')
        data = {
          entity: 'foo',
          entity_attr: 'id',
          db_class: 'bar',
          db_column: 'bar_id'
        }
        expect(DbEntityMapEntry).to receive(:new).with(data)
        dsl.map 'bar_id', 'id'
      end

      it 'maps a computed property' do
        value = -> {'foo'}
        dsl = create_dsl('foo', 'bar')
        data = {
          entity: 'foo',
          entity_attr: 'created_at',
          db_class: 'bar',
          db_column: 'created_at',
          computed_attr: value,
        }
        expect(DbEntityMapEntry).to receive(:new).with(data)
        dsl.map 'created_at', 'created_at', computed_attr: value
      end

      it 'maps a computed property that expects a value' do
        value = ->(a) {'foo'}
        dsl = create_dsl('foo', 'bar')
        data = {
          entity: 'foo',
          entity_attr: 'generated_at',
          db_class: 'bar',
          db_column: 'created_at',
          computed_attr_expect_param: value,
        }
        expect(DbEntityMapEntry).to receive(:new).with(data)
        dsl.map 'created_at', 'generated_at', computed_attr_expect_param: value
      end

      it 'maps a column that will skip all' do
        dsl = create_dsl('foo', 'bar')
        data = {
          entity: 'foo',
          entity_attr: 'blah',
          db_class: 'bar',
          db_column: 'bar_blah',
          skip_all: true
        }
        expect(DbEntityMapEntry).to receive(:new).with(data)
        dsl.map 'bar_blah', 'blah', skip_all: true
      end

      it 'maps a column that will skip_to_entity' do
        dsl = create_dsl('foo', 'bar')
        data = {
          entity: 'foo',
          entity_attr: 'blah',
          db_class: 'bar',
          db_column: 'bar_blah',
          skip_to_entity: true
        }
        expect(DbEntityMapEntry).to receive(:new).with(data)
        dsl.map 'bar_blah', 'blah', skip_to_entity: true
      end

      it 'maps a column that will skip_to_db' do
        dsl = create_dsl('foo', 'bar')
        data = {
          entity: 'foo',
          entity_attr: 'blah',
          db_class: 'bar',
          db_column: 'bar_blah',
          skip_to_db: true
        }
        expect(DbEntityMapEntry).to receive(:new).with(data)
        dsl.map 'bar_blah', 'blah', skip_to_db: true
      end
    end

    def create_dsl(entity_name, db_name)
      DbEntityMapDsl.new(entity_name, db_name)
    end
  end
end
