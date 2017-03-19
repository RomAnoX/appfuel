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

=begin
    xcontext '#where' do
      it 'builds a db relation using its map ' do
        _domain, db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')

        relation = instance_double(ActiveRecord::Relation)
        dsl.map 'foo_id', 'foo.id'
        allow(db_model).to receive(:column_names).with(no_args) { ['foo_id'] }

        mapper = create_mapper(dsl)

        criteria = create_criteria('foo.bar').where('foo.id', eq: 44)
        expect(db_model).to receive(:where).with("foo_id" => 44) { relation }

        expect(mapper.where(criteria)).to eq relation
      end

      it 'builds a db relation with a negated where' do
        _domain, db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')

        relation    = instance_double(ActiveRecord::Relation)
        where_chain = instance_double(ActiveRecord::QueryMethods::WhereChain)

        dsl.map 'foo_id', 'foo.id'
        allow(db_model).to receive(:column_names).with(no_args) { ['foo_id'] }

        mapper = create_mapper(dsl)

        expect(db_model).to receive(:where).with(no_args) { where_chain }
        expect(where_chain).to receive(:not).with("foo_id" => 44) { relation }
        criteria = create_criteria('foo.bar').where('foo.id', not_eq: 44)

        expect(mapper.where(criteria)).to eq relation
      end

      it 'builds a db relation with a or relation' do
        _domain, db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')

        relation = instance_double(ActiveRecord::Relation)
        dsl.map 'foo_id', 'foo.id'
        allow(db_model).to receive(:column_names).with(no_args) { ['foo_id'] }

        mapper = create_mapper(dsl)

        criteria = create_criteria('foo.bar')
          .where('foo.id', eq: 44)
          .or('foo.id', eq: 99)

        expect(db_model).to receive(:where).with("foo_id" => 44) { relation }
        expect(db_model).to receive(:or).with(relation) { relation }
        expect(relation).to receive(:where).with("foo_id" => 99) { relation }
        expect(mapper.where(criteria)).to eq relation
      end
    end

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
