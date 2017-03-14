module Appfuel
  RSpec.describe DbEntityMapper do
    context '#initialize' do
      it 'requires a dsl to add the first map' do
        domain   = entity_instance_double
        db_model = db_model_instance_double

        allow_type('foo.bar', domain)
        allow(domain).to receive(:basename).with(no_args) { 'bar' }
        allow_db_type('foo_bar', db_model)

        dsl = create_dsl('foo.bar', 'foo_bar')

        mapper = create_mapper(dsl)

        expect(mapper.entity_class(:bar)).to eq domain
        expect(mapper.entity_map(:bar)).to be_an_instance_of(mapper.map_class)
        expect(mapper.db_class(:bar)).to eq db_model
      end
    end

    context '#<<' do
      it 'adds another map to an existing entity' do
        domain     = entity_instance_double
        db_foo_bar = db_model_instance_double
        db_foo_baz = db_model_instance_double

        allow_type('foo.bar', domain)
        allow(domain).to receive(:basename).with(no_args) { 'bar' }
        allow_db_type('foo_bar', db_foo_bar)
        allow_db_type('foo_baz', db_foo_baz)

        dsl    = create_dsl('foo.bar', 'foo_bar')
        mapper = create_mapper(dsl)

        dsl2 = create_dsl('foo.bar', 'foo_baz', 'baz')
        mapper << dsl2

        maps = mapper.entity_maps(:bar)
        map1 = maps[:bar]
        map2 = maps[:baz]

        expect(maps).to be_a(Hash)
        expect(map1).to be_an_instance_of(DbEntityMap)
        expect(map1.db_class).to eq db_foo_bar

        expect(map2).to be_an_instance_of(DbEntityMap)
        expect(map2.db_class).to eq db_foo_baz
      end

      it 'adds a new entity and its map' do
        domain_foo = entity_instance_double
        domain_fiz = entity_instance_double

        db_foo_bar = db_model_instance_double
        db_foo_baz = db_model_instance_double

        allow_type('foo.bar', domain_foo)
        allow_type('fiz', domain_fiz)
        allow(domain_foo).to receive(:basename).with(no_args) { 'bar' }
        allow(domain_fiz).to receive(:basename).with(no_args) { 'fiz' }

        allow_db_type('foo_bar', db_foo_bar)
        allow_db_type('foo_baz', db_foo_baz)

        dsl = create_dsl('foo.bar', 'foo_bar')
        mapper = create_mapper(dsl)

        dsl2 = create_dsl('fiz', 'foo_baz')
        mapper << dsl2

        maps = mapper.entity_maps(:bar)
        map1 = maps[:bar]

        maps = mapper.entity_maps(:fiz)
        map2 = maps[:fiz]


        expect(maps).to be_a(Hash)
        expect(map1).to be_an_instance_of(DbEntityMap)
        expect(map1.db_class).to eq db_foo_bar

        expect(map2).to be_an_instance_of(DbEntityMap)
        expect(map2.db_class).to eq db_foo_baz
      end
    end

    context '#entity_class' do
      it "returns the entity class mapped with domain's basename" do
        domain, _db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        mapper = create_mapper(dsl)
        expect(mapper.entity_class('bar')).to eq domain
      end

      it 'returns false when the entity class is not mapped' do
        _domain, _db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        mapper = create_mapper(dsl)
        expect(mapper.entity_class('xxx')).to be false
      end
    end

    context '#entity_class!' do
      it "returns the entity class mapped with domain's basename" do
        domain, _db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        mapper = create_mapper(dsl)
        expect(mapper.entity_class!('bar')).to eq domain
      end

      it 'fails when the entity class is not mapped' do
        _domain, _db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        mapper = create_mapper(dsl)

        msg = 'Entity class not found at key xxx'
        expect {
          mapper.entity_class!('xxx')
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#instance_of_entity?' do
      it "returns true when the object is an instance of the entity" do
        domain, _db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')

        object = 'some domain entity'
        allow(object).to receive(:instance_of?).with(domain) { true }

        mapper = create_mapper(dsl)
        expect(mapper.instance_of_entity?('bar', object)).to be true
      end

      it 'returns false when the object is not an instance of the entity' do
        domain, _db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')

        object = 'some domain entity'
        allow(object).to receive(:instance_of?).with(domain) { false }

        mapper = create_mapper(dsl)
        expect(mapper.instance_of_entity?('bar', object)).to be false
      end

      it 'fails when the entity class is not mapped' do
        _domain, _db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        mapper = create_mapper(dsl)

        msg = 'Entity class not found at key xxx'
        expect {
          mapper.instance_of_entity?('xxx', 'some object')
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#entity_maps' do
      it 'returns a hash of maps key with map key' do
        _domain, db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        mapper = create_mapper(dsl)
        result = mapper.entity_maps('bar')

        allow(db_model).to receive(:column_names).with(no_args) { [] }
        expect(result).to be_a Hash
        expect(result[:bar]).to be_an_instance_of(DbEntityMap)

        map = result[:bar]
        expect(map.key).to eq :bar
        expect(map.db_class).to eq db_model
        # when we setup the map with the dsl we faked it with no
        # column names to the map will be empty. but it proves the
        # mapper built the correct map with this domain/db_model
        expect(map.map).to eq({})
      end

      it 'fails when the entity is not mapped' do
        _domain, _db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        mapper = create_mapper(dsl)

        msg = 'xxx is not mapped'
        expect {
          mapper.entity_maps('xxx')
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#entity_map' do
      it 'returns the db map for this entity key' do
        _domain, db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        mapper = create_mapper(dsl)
        map = mapper.entity_map('bar')

        allow(db_model).to receive(:column_names).with(no_args) { [] }

        expect(map).to be_an_instance_of(DbEntityMap)
        expect(map.key).to eq :bar
        expect(map.db_class).to eq db_model
        expect(map.map).to eq({})
      end

      it 'fails when the entity is not mapped' do
        _domain, _db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        mapper = create_mapper(dsl)

        msg = 'xxx is not mapped'
        expect {
          mapper.entity_map('xxx')
        }.to raise_error(RuntimeError, msg)
      end


      it 'fails when entity exists but the map does not' do
        _domain, _db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        mapper = create_mapper(dsl)
        msg = 'Entity is mapped at (bar), but does not have map at key (xxx)'
        expect {
          mapper.entity_map('bar.xxx')
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#each_map' do
      it 'yeilds each map with its key' do
        _domain, _db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        _domain2, _db_model2, dsl2 = setup_mapped_entity('foo.bar', 'bizzer', 'biz')

        # now we have to maps in our mapper
        mapper = create_mapper(dsl)
        mapper << dsl2

        bar_map = mapper.entity_map('bar')
        biz_map = mapper.entity_map('bar.biz')


        expect {|block|
          mapper.each_map('bar', &block)
        }.to yield_successive_args([:bar, bar_map],[:biz, biz_map])
      end
    end

    context '#db_class' do
      it 'returns the active record model mapped to an entity' do
        _domain, db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        mapper = create_mapper(dsl)

        expect(mapper.db_class('bar')).to eq db_model
      end

      it 'fails when entity is not mapped' do
        _domain, _db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        mapper = create_mapper(dsl)

        msg = 'xxx is not mapped'
        expect {
          mapper.db_class('xxx')
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when map is not mapped to existing entity' do
        _domain, _db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        mapper = create_mapper(dsl)
        msg = 'Entity is mapped at (bar), but does not have map at key (xxx)'
        expect {
          mapper.entity_map('bar.xxx')
        }.to raise_error(RuntimeError, msg)
      end

      it 'return the db_class that is not the default map' do
        # the map key for foo_bar is bar, since entity maps start from the
        # basename of its entity it would be bar.bar
        _domain, _db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        _domain2, db_model2, dsl2 = setup_mapped_entity('foo.bar', 'bizzer', 'biz')
        mapper = create_mapper(dsl)
        mapper << dsl2

        expect(mapper.db_class('bar.biz')).to eq db_model2
      end
    end

    context '#map_for_expr' do
      it 'fails when an entity attribute is not mapped' do
        _domain, db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        allow(db_model).to receive(:column_names).with(no_args) { [] }

        mapper = create_mapper(dsl)

        msg = '(bar, some_id) not mapped'
        expect {
          mapper.find_map_for_attr('bar', 'some_id')
        }.to raise_error(RuntimeError, msg)
      end

      it 'finds the correct map for an attribute' do
        _domain, db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')

        dsl.map 'my_id', 'domain.id'
        allow(db_model).to receive(:column_names).with(no_args) { ['my_id'] }

        mapper = create_mapper(dsl)
        result = mapper.find_map_for_attr('bar', 'domain.id')
        expect(result).to eq mapper.entity_map('bar')
      end

      it 'finds the correct map from two different maps' do
        _domain, db_model, dsl = setup_mapped_entity('foo.bar', 'foo_bar')
        dsl.map 'my_id', 'domain.id'
        allow(db_model).to receive(:column_names).with(no_args) { ['my_id'] }


        _domain2, db_model2, dsl2 = setup_mapped_entity('foo.bar', 'biz', 'biz')
        dsl2.map 'biz_id', 'biz.id'
        allow(db_model2).to receive(:column_names).with(no_args) { ['biz_id'] }
        mapper = create_mapper(dsl)
        mapper << dsl2

        result = mapper.find_map_for_attr('bar', 'biz.id')
        expect(result).to eq mapper.entity_map('bar.biz')
      end
    end

    context '#where' do
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

    context '#order' do
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

    def setup_mapped_entity(entity_name, db_name, map_key = nil)
        domain   = entity_instance_double
        db_model = db_model_class_double

        allow_domain_type('pager', Pager)
        allow_domain_type(entity_name, domain)
        allow_db_type(db_name, db_model)

        dsl = create_dsl(entity_name, db_name, map_key)
        [domain, db_model, dsl]
    end

    def create_dsl(domain_name, db_name, map_key = nil)
      DbEntityMapDsl.new(domain_name, db_name, map_key)
    end

    def create_mapper(dsl, map_class = nil)
      DbEntityMapper.new(dsl, map_class)
    end
  end
end
