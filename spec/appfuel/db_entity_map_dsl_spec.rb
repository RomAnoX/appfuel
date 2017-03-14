module Appfuel
  RSpec.describe DbEntityMapDsl do
    context '#initialize' do
      it 'creates an empty map' do
        expect(create_dsl('foo', 'bar').map_data).to eq({})
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
        dsl.map 'foo', 'bar'
        expect(dsl.map_data).to eq({'foo' => 'bar'})
      end

      # when mapping exprs the domain.attr is used as a simple identitfier
      # when creating an entity it is used to grab the value from the
      # sub domain's attribute
      it 'maps column to attibute of subdomain' do
        dsl = create_dsl('foo', 'bar')
        dsl.map :category_id, 'category.id'
        expect(dsl.map_data).to eq({'category_id' => 'category.id'})
      end

      it 'maps column to a value from a proc' do
        value = -> {'foo'}
        dsl = create_dsl('foo', 'bar')
        dsl.map :created_at, value
        result = {
          'created_at' => {call: value, name: 'created_at', skip: false}
        }
        expect(dsl.map_data).to eq result
      end

      it 'maps proc value to entity attribute' do
        value = -> {'foo'}
        dsl = create_dsl('foo', 'bar')
        dsl.map :created_at, value, as: 'baz'
        result = {
          'created_at' => {call: value, name: 'baz', skip: false}
        }
        expect(dsl.map_data).to eq result
      end

      it 'fails when mapping value is an Int' do
        dsl = create_dsl('foo', 'bar')
        msg = 'attr must be a string, symbol or proc for created_at'
        expect {
          dsl.map :created_at, 1234
        }.to raise_error(ArgumentError, msg)
      end

      it 'fails when mapping is an object' do
        dsl = create_dsl('foo', 'bar')
        msg = 'attr must be a string, symbol or proc for created_at'
        expect {
          dsl.map :created_at, Object.new
        }.to raise_error(ArgumentError, msg)
      end

      it 'maps the column name when entity_method is nil' do
        dsl = create_dsl('foo', 'bar')
        dsl.map 'category_id'
        expect(dsl.map_data).to eq({'category_id' => 'category_id'})
      end

      it 'fails when mapping is an empty string' do
        dsl = create_dsl('foo', 'bar')
        msg = 'entity attr is empty for created_at'
        expect {
          dsl.map :created_at, ''
        }.to raise_error(ArgumentError, msg)
      end
    end

    def create_dsl(entity_name, db_name)
      DbEntityMapDsl.new(entity_name, db_name)
    end
  end
end
