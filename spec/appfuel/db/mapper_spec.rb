module Appfuel::Db
  RSpec.describe Mapper do
    context '#registry' do
      it 'is a reference to the mapping registry' do
        mapper = setup_mapper
        expect(mapper.registry).to eq mapping_registry
      end
    end

    context '#entity_mapped?' do
      it 'delegates to the registry :entity?' do
        mapper = setup_mapper
        expect(mapping_registry).to receive(:entity?).with('foo.bar')
        mapper.entity_mapped?('foo.bar')
      end
    end

    context '#db_class' do
      it 'delegates to the registry' do
        mapper = setup_mapper
        expect(mapping_registry).to receive(:db_class).with('foo.bar', 'id')
        mapper.db_class('foo.bar', 'id')
      end
    end

    context '#gt_value' do
      it 'returns a range with the value + 1 to infinity' do
        value  = 5
        mapper = setup_mapper
        expect(mapper.gt_value(value)).to eq((value + 1) ... Float::INFINITY)
      end
    end

    context '#gteq_value' do
      it 'returns a range with the value + 1 to infinity' do
        value  = 5
        mapper = setup_mapper
        expect(mapper.gteq_value(value)).to eq(value  ... Float::INFINITY)
      end
    end

    context '#lt_value' do
      it 'returns a range with the value + 1 to infinity' do
        value  = 5
        mapper = setup_mapper
        expect(mapper.lt_value(value)).to eq(Float::INFINITY ... value)
      end
    end

    context '#lteq_value' do
      it 'returns a range with the value + 1 to infinity' do
        value  = 5
        mapper = setup_mapper
        expect(mapper.lteq_value(value)).to eq(Float::INFINITY .. value)
      end
    end

    context '#expr_value' do
      it 'returns the value when there is no strategy for the operator' do
        value  = 5
        mapper = setup_mapper
        expr = create_expr('foo', 'bar.id', eq: value)
        expect(mapper.expr_value(expr)).to eq(value)
      end

      it 'delegates to "gt_value" for the operator gt' do
        value  = 5
        mapper = setup_mapper
        expr   = create_expr('foo', 'bar.id', gt: value)
        expect(mapper).to receive(:gt_value).with(5)
        mapper.expr_value(expr)
      end

      it 'delegates to "gteq_value" for the operator gteq' do
        value  = 10
        mapper = setup_mapper
        expr   = create_expr('foo', 'bar.id', gteq: value)
        expect(mapper).to receive(:gteq_value).with(10)
        mapper.expr_value(expr)
      end

      it 'delegates to "lt_value" for the operator lt' do
        value  = 8
        mapper = setup_mapper
        expr   = create_expr('foo', 'bar.id', lt: value)
        expect(mapper).to receive(:lt_value).with(8)
        mapper.expr_value(expr)
      end

      it 'delegates to "lteq_value" for the operator lt' do
        value  = 9
        mapper = setup_mapper
        expr   = create_expr('foo', 'bar.id', lteq: value)
        expect(mapper).to receive(:lteq_value).with(9)
        mapper.expr_value(expr)
      end
    end

    context 'entity_expr' do
      it 'maps the entity expr to database columns' do
        mapper = setup_mapper
        mapping_registry << create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'bar.id',
          db_class: 'barish',
          db_column: 'bar_id'
        )

        expr   = create_expr('foo.bar', 'bar.id', eq: 6)
        result = {"bar_id" => 6}
        expect(mapper.entity_expr(expr)).to eq result
      end
    end

    context 'undefined?' do
      it 'returns false when the value is not of type Types::Undefined' do
        mapper = setup_mapper
        expect(mapper.undefined?('some value')).to be false
      end

      it 'returns true when the value is of type Types::Undefined' do
        mapper = setup_mapper
        expect(mapper.undefined?(Types::Undefined)).to be true
      end
    end

    context 'db_where' do
      it 'converts expr to db columns and delegates where to relation' do
        mapper = setup_mapper
        mapping_registry << create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'bar.id',
          db_class: 'barish',
          db_column: 'bar_id'
        )
        expr   = create_expr('foo.bar', 'bar.id', eq: 6)
        relation = double('some relation')
        column_hash = {
          'bar_id' => 6
        }
        expect(relation).to receive(:where).with(column_hash)
        mapper.db_where(expr, relation)
      end

      it 'returns the relation that was passed in' do
        mapper = setup_mapper
        mapping_registry << create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'bar.id',
          db_class: 'barish',
          db_column: 'bar_id'
        )
        expr   = create_expr('foo.bar', 'bar.id', eq: 6)
        relation = double('some relation')
        column_hash = {
          'bar_id' => 6
        }
        allow(relation).to receive(:where).with(column_hash) { relation }
        expect(mapper.db_where(expr, relation)).to eq relation
      end

      it 'delegates to not when expr is negated' do
        mapper = setup_mapper
        mapping_registry << create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'bar.id',
          db_class: 'barish',
          db_column: 'bar_id'
        )
        expr   = create_expr('foo.bar', 'bar.id', not_eq: 6)
        relation = double('some relation')
        column_hash = {
          'bar_id' => 6
        }
        expect(relation).to receive(:where).with(no_args) { relation }
        expect(relation).to receive(:not).with(column_hash) { relation }
        expect(mapper.db_where(expr, relation)).to eq relation
      end
    end

    context '#retrieve_entity_value' do
      it 'retrieve an attribute at the root level of the entity' do
        mapper = setup_mapper
        entity = Object.new
        value  = 123
        entity.instance_eval do
          define_singleton_method(:id) do
            value
          end
        end
        expect(mapper.retrieve_entity_value(entity, 'id')).to eq value
      end

      it 'retrieve an attribute inside another object' do
        mapper = setup_mapper
        entity = Object.new
        bar    = Object.new
        value  = 123
        bar.instance_eval do
          define_singleton_method(:id) do
            value
          end
        end

        entity.instance_eval do
          define_singleton_method(:bar) do
            bar
          end
        end

        expect(mapper.retrieve_entity_value(entity, 'bar.id')).to eq value
      end

      it 'can retrieve three levels deep' do
        mapper = setup_mapper
        entity = Object.new
        bar    = Object.new
        baz    = Object.new
        value  = 123
        baz.instance_eval do
          define_singleton_method(:id) do
            value
          end
        end
        bar.instance_eval do
          define_singleton_method(:baz) do
            baz
          end
        end
        entity.instance_eval do
          define_singleton_method(:bar) do
            bar
          end
        end
        expect(mapper.retrieve_entity_value(entity, 'bar.baz.id')).to eq value

      end

      it 'returns nil when object does not respond to attr' do
        mapper = setup_mapper
        entity = Object.new
        expect(mapper.retrieve_entity_value(entity, 'bar.baz.id')).to eq nil
      end
    end

    context '#entity_value' do
      it 'returns the value for the entity attibute' do
        mapper = setup_mapper
        entity = Object.new
        value  = 123
        entity.instance_eval do
          define_singleton_method(:id) do
            value
          end
        end
        entry = create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'id',
          db_class: 'barish',
          db_column: 'bar_id'
        )

        expect(mapper.entity_value(entity, entry)).to eq 123
      end

      it 'returns nil when the value is undefined' do
        mapper = setup_mapper
        entity = Object.new
        value  = Types::Undefined
        entity.instance_eval do
          define_singleton_method(:id) do
            value
          end
        end
        entry = create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'id',
          db_class: 'barish',
          db_column: 'bar_id'
        )
        expect(mapper.entity_value(entity, entry)).to eq nil
      end

      it "delegates to the mapping entry's computed attribute" do
        mapper = setup_mapper
        entity = Object.new
        value  = 123
        entity.instance_eval do
          define_singleton_method(:id) do
            value
          end
        end
        entry = create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'id',
          db_class: 'barish',
          db_column: 'bar_id',
          computed_attr: ->(entity_value) { 'abc' }
        )
        expect(mapper.entity_value(entity, entry)).to eq 'abc'
      end

      it 'returns nil when a computed attribute returns undefined' do
        mapper = setup_mapper
        entity = Object.new
        value  = 123
        entity.instance_eval do
          define_singleton_method(:id) do
            value
          end
        end
        entry = create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'id',
          db_class: 'barish',
          db_column: 'bar_id',
          computed_attr: ->(entity_value) { Types::Undefined }
        )
        expect(mapper.entity_value(entity, entry)).to eq nil
      end
    end

    context 'to_db' do
      it 'maps entity attributes to db columns' do
        mapper = setup_mapper
        mapping_registry << create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'id',
          db_class: 'barish',
          db_column: 'bar_id',
        )

        mapping_registry << create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'other_value',
          db_class: 'barish',
          db_column: 'db_other',
        )

        entity = Object.new
        def entity.domain_name
          'foo.bar'
        end

        def entity.id
          123
        end
        def entity.other_value
          'abc'
        end

        result = {'barish' => {'bar_id' => 123, 'db_other' => 'abc'}}
        expect(mapper.to_db(entity)).to eq result
      end

      it 'maps entity attributes to db columns for two tables' do
        mapper = setup_mapper
        mapping_registry << create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'id',
          db_class: 'barish',
          db_column: 'bar_id',
        )

        mapping_registry << create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'other_value',
          db_class: 'barish',
          db_column: 'db_other',
        )

        mapping_registry << create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'fiz_id',
          db_class: 'fizzish',
          db_column: 'fizish_id',
        )

        entity = Object.new

        def entity.fiz_id
          999
        end

        def entity.domain_name
          'foo.bar'
        end

        def entity.id
          123
        end
        def entity.other_value
          'abc'
        end

        result = {
          'barish' => {'bar_id' => 123, 'db_other' => 'abc'},
          'fizzish' => {'fizish_id' => 999}
        }
        expect(mapper.to_db(entity)).to eq result
      end


      it 'will exclude columns given in the options' do
        mapper = setup_mapper
        mapping_registry << create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'id',
          db_class: 'barish',
          db_column: 'bar_id',
        )

        mapping_registry << create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'other_value',
          db_class: 'barish',
          db_column: 'db_other',
        )

        entity = Object.new
        def entity.domain_name
          'foo.bar'
        end

        def entity.id
          123
        end
        def entity.other_value
          'abc'
        end

        result = {'barish' => {'bar_id' => 123}}
        expect(mapper.to_db(entity, exclude: ['db_other'])).to eq result
      end

      it 'will exclude any column whose entry has skip_to_db enabled' do
        mapper = setup_mapper
        mapping_registry << create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'id',
          db_class: 'barish',
          db_column: 'bar_id',
        )

        mapping_registry << create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'other_value',
          db_class: 'barish',
          db_column: 'db_other',
          skip_to_db: true
        )

        entity = Object.new

        def entity.domain_name
          'foo.bar'
        end

        def entity.id
          123
        end
        def entity.other_value
          'abc'
        end

        result = {
          'barish' => {'bar_id' => 123}
        }
        expect(mapper.to_db(entity)).to eq result
      end
    end

    context '#where' do
      it "fails when criteria has no exprs and 'all' was not called" do
        criteria = create_criteria('foo.bar')
        mapper   = setup_mapper
        relation = double('some db model')
        msg = 'you must explicitly call :all when criteria has no exprs'
        expect {
          mapper.where(criteria, relation)
        }.to raise_error(RuntimeError, msg)
      end

      it 'delegated to the relation where interface with mapped columns' do
        mapper = setup_mapper
        mapping_registry << create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'id',
          db_class: 'barish',
          db_column: 'bar_id',
        )

        mapping_registry << create_mapping_entry(
          entity: 'foo.bar',
          entity_attr: 'other_value',
          db_class: 'barish',
          db_column: 'db_other',
        )
        criteria = create_criteria('foo.bar').where('id', eq: 123)
        relation = double('some db model')

        columns = {'bar_id' => 123}

        expect(relation).to receive(:where).with(columns) { relation }
        result = mapper.where(criteria, relation)
        expect(result).to eq relation

      end
    end

=begin
    xcontext '#order' do
      it 'returns the relation when there is no order' do
        _domain, db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')

        mapper = create_mapper(dsl)

        criteria = create_criteria('foo.bar').where('foo.id', eq: 44)
        expect(mapper.order(criteria, db_model)).to eq db_model
      end

      it 'builds an order expression using criteria' do
        _domain, db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')

        dsl.map 'foo_id', 'foo.id'
        allow(db_model).to receive(:column_names).with(no_args) { ['foo_id'] }

        mapper = create_mapper(dsl)

        criteria = create_criteria('foo.bar')
          .where('foo.id', eq: 45)
          .order_by('foo.id', :desc)

        response = 'i am what order returns'
        expect(db_model).to receive(:order).with("foo_id" => :desc) { response }
        expect(mapper.order(criteria, db_model)).to eq response
      end

      it 'fails when the entity attr is not mapped' do
        _domain, db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        allow(db_model).to receive(:column_names).with(no_args) { [] }

        mapper = create_mapper(dsl)

        criteria = create_criteria('foo.bar')
          .where('foo.id', eq: 45)
          .order_by('foo.id', :desc)

        msg = '(bar, foo.id) not mapped'
        expect {
          mapper.order(criteria, db_model)
        }.to raise_error(RuntimeError, msg)
      end
    end
=end

    def create_mapping_entry(data)
      Appfuel::Db::MappingEntry.new(data)
    end

    def create_expr(entity, entity_attr, data)
      Appfuel::EntityExpr.new(entity, entity_attr, data)
    end

    def mapping_registry
      Appfuel::Db::MappingRegistry
    end

    def setup_mapper
      obj = Object.new
      obj.extend(Mapper)
      obj
    end
  end
end
