module Appfuel
  RSpec.describe DbEntityMap do
    context '#initialize' do
      it 'requires a Hash for a map' do
        map    = {'foo' => 'bar'}
        mapper = create_map('mapkey', map, mock_db_class('foo'))
        result = mapper.send(:instance_variable_get, :@map)
        expect(result).to be_an_instance_of(Hash)
        expect(result).to eq(map)
      end

      it 'assigns the map key' do
        map    = {'foo' => 'bar'}
        mapper = create_map('mapkey', map, mock_db_class('foo'))
        expect(mapper.key).to eq(:mapkey)
      end

      it 'fails then the map is not a hash' do
        msg = 'map must be a hash'
        expect {
          create_map('mapkey', 'blah', mock_db_class('foo'))
        }.to raise_error(ArgumentError, msg)
      end

      it 'assigns the db model' do
        db_model = mock_db_class('bar')
        mapper = create_map('mapkey', {'foo' => 'bar'}, db_model)
        expect(mapper.db_class).to eq db_model
      end

      it 'does not validate the map' do
        db_model = mock_db_class('bar')
        mapper = create_map('mapkey', {'foo' => 'bar'}, db_model)
        lookup = mapper.send(:instance_variable_get, :@lookup)
        expect(lookup).to eq([])
      end
    end

    context '#map' do
      it 'validates the map before returning' do
        db_model = mock_db_class('foo')
        map = {
          "fizz" => "bar",
          "biz"  => "biz",
          "baz"  => "baz"
        }
        columns = [ 'fizz', 'biz', 'baz' ]
        allow_db_column_names(db_model, columns)
        mapper = create_map('mapkey', map, db_model)
        expect(mapper.map).to eq map
      end

      it 'assigns looks to map when validated' do
        db_model = mock_db_class('foo')
        map = {
          "fizz" => "bar",
          "biz"  => "biz",
          "baz"  => "baz"
        }
        columns = [ 'fizz', 'biz', 'baz' ]
        allow_db_column_names(db_model, columns)
        mapper = create_map('mapkey', map, db_model)

        mapper.map
        lookup = mapper.send(:instance_variable_get, :@lookup)
        expect(lookup).to eq ['bar', 'biz', 'baz']
      end

      it 'assigns the name key an entity value that is a hash' do
        db_model = mock_db_class('foo')
        map = {
          "fizz" => {call: ->{}, name: 'bar'},
          "biz"  => "biz",
          "baz"  => "baz"
        }
        columns = [ 'fizz', 'biz', 'baz' ]
        allow_db_column_names(db_model, columns)
        mapper = create_map('mapkey', map, db_model)

        mapper.map
        lookup = mapper.send(:instance_variable_get, :@lookup)
        expect(lookup).to eq ['bar', 'biz', 'baz']
      end
    end

    context 'attr_mapped?' do
      it 'returns true when the entity attr is mapped' do
        db_model = mock_db_class('foo')
        map = {
          "fizz" => "bar",
          "biz"  => "biz",
          "baz"  => "baz"
        }
        columns = [ 'fizz', 'biz', 'baz' ]
        allow_db_column_names(db_model, columns)
        mapper = create_map('mapkey', map, db_model)
        expect(mapper.attr_mapped?('bar')).to be true
      end

      it 'returns false when the entity attr is not mapped' do
        db_model = mock_db_class('foo')
        map = {
          "fizz" => "bar",
          "biz"  => "biz",
        }
        columns = [ 'fizz', 'biz' ]
        allow_db_column_names(db_model, columns)
        mapper = create_map('mapkey', map, db_model)
        expect(mapper.attr_mapped?('baz')).to be false
      end
    end

    context 'column_mapped?' do
      it 'returns true when the column is mapped' do
        db_model = mock_db_class('foo')
        map = { "col_a" => "bar", }
        allow_db_column_names(db_model, ['col_a'])
        mapper = create_map('mapkey', map, db_model)
        expect(mapper.column_mapped?('col_a')).to be true
      end

      it 'returns false when the column is not mapped' do
        db_model = mock_db_class('foo')
        map = { "col_a" => "bar", }
        allow_db_column_names(db_model, ['col_a'])
        mapper = create_map('mapkey', map, db_model)
        expect(mapper.column_mapped?('col_b')).to be false
      end
    end

    context 'expr' do
      it 'returns the db column with its corresponding entity value ' do
        db_model = mock_db_class('foo')
        map = { "category_id" => "category.id", }
        allow_db_column_names(db_model, ['category_id'])
        mapper = create_map('mapkey', map, db_model)

        expr   = create_expr('category.id', eq: 4)
        result = { 'category_id' => 4 }

        expect(mapper.entity_expr(expr)).to eq result
      end

      it 'adds the mapped expression to a given result hash' do
        db_model = mock_db_class('foo')
        map = { "category_id" => "category.id", }
        allow_db_column_names(db_model, ['category_id'])
        mapper = create_map('mapkey', map, db_model)


        expr   = create_expr('category.id', eq: 4)
        result = { 'foo' => 'bar' }
        expected = { 'foo' => 'bar', 'category_id' => 4 }
        expect(mapper.entity_expr(expr, result)).to eq expected
      end

      it 'fails when attribute is not mapped' do
        db_model = mock_db_class('foo')
        map = { "category_id" => "category.id", }
        allow_db_column_names(db_model, ['category_id'])
        mapper = create_map('mapkey', map, db_model)
        expr   = create_expr('foo.id', eq: 4)

        msg = 'attribute foo.id is not mapped'
        expect {
          mapper.entity_expr(expr)
        }.to raise_error(RuntimeError, msg)
      end
    end

    context 'to_db' do
      it 'maps sub entity attributes to db columns' do
        db_model = mock_db_class('document_category')
        map = { "category_id" => "category.id", "code" => "category.code"}
        allow_db_column_names(db_model, ['category_id', 'code'])
        mapper = create_map('mapkey', map, db_model)

        entity = {
          category: {
            id:  123,
            code: 'mycode'
          }
        }

        expected_result = {
          "category_id" => 123,
          "code" => 'mycode'
        }

        expect(mapper.to_db(entity)).to eq expected_result
      end

      it 'maps entity properties to db columns' do
        db_model = mock_db_class('some_table')
        map = { "column_a" => "property_a", "column_b" => "property_b"}
        allow_db_column_names(db_model, ['column_a', 'column_b'])
        mapper = create_map('mapkey', map, db_model)

        entity = {
          property_a: 'value_a',
          property_b: 'value_b'
        }

        expected_result = {
          'column_a' => 'value_a',
          'column_b' => 'value_b'
        }
        expect(mapper.to_db(entity)).to eq expected_result
      end

      it 'does not map excluded properties' do
        db_model = mock_db_class('some_table')
        map = { "column_a" => "property_a", "column_b" => "property_b"}
        allow_db_column_names(db_model, ['column_a', 'column_b'])
        mapper = create_map('mapkey', map, db_model)

        entity = {
          property_a: 'value_a',
          property_b: 'value_b'
        }

        expected_result = {
          'column_b' => 'value_b'
        }
        exclude = ['column_a']
        expect(mapper.to_db(entity, exclude: exclude)).to eq expected_result
      end

      it 'does not mapped any columns marked as skip' do
        db_model = mock_db_class('some_table')
        map = {
          "column_a" => {name: "property_a", skip: true},
          "column_b" => "property_b"
        }
        allow_db_column_names(db_model, ['column_a', 'column_b'])
        mapper = create_map('mapkey', map, db_model)

        entity = {
          property_a: 'value_a',
          property_b: 'value_b'
        }

        expected_result = {
          'column_b' => 'value_b'
        }
        exclude = ['column_a']
        expect(mapper.to_db(entity, exclude: exclude)).to eq expected_result
      end

      it 'maps a combination of properties and sub domain properties' do
        db_model = mock_db_class('some_table')
        map = {
          "column_a" => "property_a",
          "column_b" => "b.property_b",
          "column_c" => "c.property_c"
        }
        allow_db_column_names(db_model, ['column_a', 'column_b', 'column_c'])
        mapper = create_map('mapkey', map, db_model)

        entity = {
          property_a: 'value_a',
          b: { property_b: 'value_b'},
          c: { property_c: 'value_c'}
        }

        expected_result = {
          'column_a' => 'value_a',
          'column_b' => 'value_b',
          'column_c' => 'value_c'
        }
        expect(mapper.to_db(entity)).to eq expected_result
      end

      it 'maps entity attribute (Proc) to db column' do
        db_model = mock_db_class('document')
        now      = Time.now
        map      = {
          "column_a" => {call: ->{now}, name: "property_b"},
          "column_b" => "property_b",
        }
        mapper   = create_map('mapkey', map, db_model)

        allow_db_column_names(db_model, ["column_a", "column_b"])

        entity = {
          property_b: 'value_b',
        }

        expected_result = {
          'column_a' => now,
          'column_b' => 'value_b',
        }
        expect(mapper.to_db(entity)).to eq expected_result
      end

      it 'fails property does not exist in entity hash' do
        db_model = mock_db_class('document')
        map      = { "column_a" => "property_a"}
        mapper   = create_map('mapkey', map, db_model)
        allow_db_column_names(db_model, ["column_a"])
        entity = {foo:  'bar'}

        msg = 'mapkey: (property_a) not found'
        expect {
          mapper.to_db(entity)
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when child entity hash not found' do
        db_model = mock_db_class('document')
        map      = { "column_a" => "a.property_a"}
        mapper   = create_map('mapkey', map, db_model)
        allow_db_column_names(db_model, ["column_a"])
        entity = {foo:  'bar'}

        msg = 'mapkey: child (a) not found'
        expect {
          mapper.to_db(entity)
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when child entity property is not found' do
        db_model = mock_db_class('document')
        map      = { "column_a" => "a.property_a"}
        mapper   = create_map('mapkey', map, db_model)
        allow_db_column_names(db_model, ["column_a"])
        entity = {a:  {foo: 'bar'}}

        msg = 'mapkey: child (a) property (property_a) not found'
        expect {
          mapper.to_db(entity)
        }.to raise_error(RuntimeError, msg)
      end
    end

    context 'to_entity' do
      it 'maps db model to entity hash' do
        db_model = instance_double('some active record model')
        map      = {"column_a" => "property_a"}
        mapper   = create_map('mapkey', map, db_model)
        attrs    = {column_a: 'abc'}
        allow_db_column_names(db_model, ["column_a"])
        allow_db_entity_attributes(db_model, attrs)

        expected_result = {property_a: 'abc'}
        expect(mapper.to_entity(db_model)).to eq(expected_result)
      end

      it 'maps sub entity attributes to entity' do
        db_model = instance_double('some active record model')
        map      = {"column_a" => "a.property_a"}
        mapper   = create_map('mapkey', map, db_model)
        attrs    = {column_a: 'abc'}
        allow_db_column_names(db_model, ["column_a"])
        allow_db_entity_attributes(db_model, attrs)

        expected_result = {
          a: { property_a: 'abc' }
        }
        expect(mapper.to_entity(db_model)).to eq(expected_result)
      end

      it 'skips column from being added to entity' do
        db_model = instance_double('some active record model')
        map = {
          "column_a" => {name: "property_a", skip: true},
          "column_b" => "property_b"
        }
        mapper   = create_map('mapkey', map, db_model)
        attrs    = {column_a: 'abc', column_b: 'xyz'}
        allow_db_column_names(db_model, ["column_a", "column_b"])
        allow_db_entity_attributes(db_model, attrs)

        expected_result = {property_b: 'xyz'}
        expect(mapper.to_entity(db_model)).to eq(expected_result)
      end

      it 'excludes column from being added to entity' do
        db_model = instance_double('some active record model')
        map = {
          "column_a" => "property_a",
          "column_b" => "property_b"
        }
        mapper   = create_map('mapkey', map, db_model)
        attrs    = {column_a: 'abc', column_b: 'xyz'}
        allow_db_column_names(db_model, ["column_a", "column_b"])
        allow_db_entity_attributes(db_model, attrs)

        exclude = ['column_a']
        expected_result = {property_b: 'xyz'}
        expect(mapper.to_entity(db_model, exclude: exclude)).to eq(expected_result)
      end
    end
=begin
    xcontext '#where' do
      it 'returns the db model if there are no expressions' do
        db_class = mock_db_class('document')
        mock_entity_class('template')
        map    = {'foo' => 'bar'}

        allow_db_column_names(db_class, ["foo"])
        expect(db_class).to receive(:where).with({"foo" => 12345}) { db_class }
        mapper = DbEntityMap.new(map, 'document', 'template')

        criteria = create_criteria('template')
        criteria.where('bar', eq: 12345)

        expect(mapper.where(criteria)).to eq mapper.db_class
      end
    end
=end
    def create_expr(attr, value)
      EntityExpr.new(attr, value)
    end

    def create_criteria(name = 'foo.bar')
      Criteria.new(name)
    end

    def create_map(key, map, db)
      DbEntityMap.new(key, map, db)
    end
  end
end
