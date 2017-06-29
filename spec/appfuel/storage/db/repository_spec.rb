require 'appfuel/storage/db'

module Appfuel::Db
  RSpec.xdescribe Repository do

    context '#execute_query' do
      it 'delegates to another method in the repository' do
        repo = setup_mixin
        repo.instance_eval do
          define_singleton_method(:foo_query) do |criteria|
            'some result'
          end
        end

        criteria = create_criteria('foo.bar').exec('foo')
        result = repo.execute_criteria(criteria)
        expect(result).to eq('some result')
      end

      it 'fails when method does not exist on repo' do
        msg  = 'Could not execute method foo_query'
        repo = setup_mixin
        criteria = create_criteria('foo.bar').exec('foo')
        expect {
          repo.execute_criteria(criteria)
        }.to raise_error(RuntimeError, msg)
      end
    end


    context '#query_relation' do
      it 'delegates to another method in the repository' do
        repo = setup_mixin
        repo.instance_eval do
          define_singleton_method(:my_domain_query) do |criteria|
            'some result'
          end
        end

        criteria = create_criteria('my_feature.my_domain')
        result = repo.query_relation(criteria)
        expect(result).to eq('some result')
      end

      it 'fails when method does not exist on repo' do
        msg  = 'Could not execute method my_domain_query'
        repo = setup_mixin
        criteria = create_criteria('my_feature.my_domain')
        expect {
          repo.query_relation(criteria)
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#create_entity_not_found' do
      xit 'creates an entity not found null object for the criteria domain' do
        domain_class = class_double(Appfuel::Domain::Entity)
        domain       = instance_double(Appfuel::Domain::Entity)
        allow_domain_type('foo.bar', domain_class)
        allow(domain_class).to receive(:new).with({}) { domain }
        allow(domain).to receive(:domain_name).with(no_args) { 'foo.bar' }
        criteria = create_criteria('foo.bar')
        repo = setup_mixin
        null_object = repo.create_entity_not_found(criteria)
        expect(null_object).to be_an_instance_of(Appfuel::Domain::EntityNotFound)
      end
    end

    context '#handle_empty_relation' do
      it 'returns error interface when criteria expects error on empty' do
        repo     = setup_mixin
        criteria = create_criteria('foo.bar', error_on_empty: true)
        relation = double('some db model class')
        error    = double('some error')
        repo.instance_eval do
          define_singleton_method(:error) do |data|
            return error
          end
        end

        allow(relation).to receive(:blank?).with(no_args) { true }
        result = repo.handle_empty_relation(criteria, relation)
        expect(result).to eq(error)
      end

      xit 'return entity not found when criteria expects a single entity' do
        repo      = setup_mixin
        criteria  = create_criteria('foo.bar', single: true)
        relation  = double('some relation')
        domain    = double(Appfuel::Domain::Entity)

        domain_class = class_double(Appfuel::Domain::Entity)
        domain       = instance_double(Appfuel::Domain::Entity)
        allow_domain_type('foo.bar', domain_class)
        allow(domain_class).to receive(:new).with({}) { domain }
        allow(domain).to receive(:domain_name).with(no_args) { 'foo.bar' }
        allow(relation).to receive(:blank?).with(no_args) { true }

        result = repo.handle_empty_relation(criteria, relation)
        expect(result).to be_an_instance_of(Appfuel::Domain::EntityNotFound)
      end

      it 'returns nil when the criteria does not care about empty' do
        repo      = setup_mixin
        criteria  = create_criteria('foo.bar')
        relation  = double('some relation')

        expect(repo.handle_empty_relation(criteria, relation)).to eq nil
      end
    end

    context '#apply_query_conditions' do
      xit 'delegates to where, order, and limit' do
        repo      = setup_mixin
        criteria  = create_criteria('foo.bar')
        start_relation = double('starting relation')
        where_relation = double('where relation')
        order_relation = double('order relation')
        limit_relation = double('limit relation')

        expect(repo).to receive(:where).with(criteria, start_relation) {
          where_relation
        }

        expect(repo).to receive(:order).with(criteria, where_relation) {
          order_relation
        }

        expect(repo).to receive(:limit).with(criteria, order_relation) {
          limit_relation
        }

        expect(repo.apply_query_conditions(criteria, start_relation)).to(
          eq limit_relation
        )
      end
    end

    context '#apply_query_all' do
      xit "delegates to the relation's :all and limit interfaces" do
        repo           = setup_mixin
        criteria       = create_criteria('foo.bar').all
        start_relation = double('starting relation')
        all_relation   = double('all relation')
        order_relation = double('order relation')
        expect(start_relation).to receive(:all).with(no_args) { all_relation }
        expect(repo).to receive(:order).with(criteria, all_relation) {
          order_relation
        }

        expect(repo.apply_query_all(criteria, start_relation)).to eq(
          order_relation
        )
      end

      it 'fails when the criteria did not explicitly call :all' do
        repo      = setup_mixin
        criteria  = create_criteria('foo.bar')
        relation  = double('starting relation')
        msg = 'This interface can only be used when the criteria :all is used'
        expect {
          repo.apply_query_all(criteria, relation)
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#handle_query_conditions' do
      it 'delegates to the "all" interface when criteria "all" is used' do
        repo     = setup_mixin
        criteria = create_criteria('foo.bar').all
        relation = double('some relation')
        expect(repo).to receive(:apply_query_all).with(criteria, relation)
        repo.handle_query_conditions(criteria, relation)
      end

      it 'delegates to the query conditions when criteria "all" is not used' do
        repo     = setup_mixin
        criteria = create_criteria('foo.bar')
        relation = double('some relation')
        expect(repo).to receive(:apply_query_conditions).with(criteria, relation)
        repo.handle_query_conditions(criteria, relation)
      end
    end

    context 'create_entity_builder' do
      it 'fails when the builder class does not exist' do
        repo     = setup_mixin
        criteria = create_criteria('bar')
        root     = double('some module')

        msg = 'Entity Builder (Builder::DbBar) not found for ' +
              '#[Double "some module"]'
        allow_const_defined_as_false(root, 'Builder::DbBar')
        allow(repo).to receive(:root_module).with(no_args) { root }
        expect {
          repo.create_entity_builder(criteria)
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when the feature does not exist' do
        repo     = setup_mixin
        criteria = create_criteria('foo.fiz')
        root     = double('some module')

        allow_const_defined_as_false(root, 'Foo')
        allow(repo).to receive(:root_module).with(no_args) { root }

        msg = 'Feature (Foo) not found for #[Double "some module"]'
        expect {
          repo.create_entity_builder(criteria)
        }.to raise_error(RuntimeError, msg)
      end

      it 'returns a builder class for a global domain' do
        repo     = setup_mixin
        criteria = create_criteria('bar')
        root     = double('root module')
        builder  = double('some builder class')
        builder_instance = double('instance of builder')

        allow_const_defined_as_true(root, 'Builder::DbBar')
        allow_const_get(root, 'Builder::DbBar', builder)
        allow(builder).to receive(:new).with(no_args) { builder_instance }
        allow(repo).to receive(:root_module).with(no_args) { root }

        expect(repo.create_entity_builder(criteria)).to eq builder_instance
      end

      it 'returns a build class for a feature domain' do
        repo     = setup_mixin
        criteria = create_criteria('foo.bar')
        root     = double('root module')
        feature  = double('feature module')
        builder  = double('some builder class')
        builder_instance = double('instance of builder')

        allow_const_defined_as_true(root, 'Foo')
        allow_const_get(root, 'Foo', feature)

        allow_const_defined_as_true(feature, 'Builder::DbBar')
        allow_const_get(feature, 'Builder::DbBar', builder)
        allow(builder).to receive(:new).with(no_args) { builder_instance }
        allow(repo).to receive(:root_module).with(no_args) { root }

        expect(repo.create_entity_builder(criteria)).to eq builder_instance
      end

      it 'fails when feature builder is not found' do
        repo     = setup_mixin
        criteria = create_criteria('foo.bar')
        root     = double('root module')
        feature  = double('feature module')

        allow_const_defined_as_true(root, 'Foo')
        allow_const_get(root, 'Foo', feature)

        allow_const_defined_as_false(feature, 'Builder::DbBar')
        allow(repo).to receive(:root_module).with(no_args) { root }

        msg = 'Entity Builder (Builder::DbBar) not found for ' +
              '#[Double "feature module"]'
        expect {
          repo.create_entity_builder(criteria)
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#create_pager_result' do
      xit 'creates an Appfuel::Pagination::Result' do
        repo = setup_mixin
        data = {
          total_pages:  1,
          current_page: 2,
          total_count:  3,
          limit_value:  4,
          page_size:    4
        }
        results = repo.create_pager_result(data)
        expect(results).to be_an_instance_of(Appfuel::Pagination::Result)
      end
    end

    context '#create_entity_collection' do
      it 'creates an Appfuel::Domain::EntityCollection' do

        repo = setup_mixin
        entity = double('foo.bar')
        allow_domain_type('foo.bar', entity)

        name = 'foo.bar'
        results = repo.create_entity_collection(name)
        expect(results).to be_an_instance_of(Appfuel::Domain::EntityCollection)
        expect(results.domain_name).to eq(name)
      end
    end

    context '#entity_loader' do
      it 'returns a lamdba to be used in the entity collection' do
        repo = setup_mixin
        criteria = double('some criteria')
        relation = double('some relation')
        builder  = double('some builder')
        results = repo.entity_loader(criteria, relation, builder)
        expect(results.lambda?).to be true
      end
    end

    context '#load_collection' do
      xit 'loads a collection of entities' do
        repo     = setup_mixin
        criteria = create_criteria('foo.bar')
        relation = double('some relation')
        builder  = double('some builder')

        db1 = double('some db item')
        db2 = double('some other db item')

        pager = criteria.pager
        allow(relation).to receive(:page).with(pager.page) { relation }
        allow(relation).to receive(:per).with(pager.per_page) { relation }
        allow(relation).to receive(:total_pages).with(no_args) { 5 }
        allow(relation).to receive(:current_page).with(no_args) { 6 }
        allow(relation).to receive(:total_count).with(no_args) { 7 }
        allow(relation).to receive(:limit_value).with(no_args) { 8 }
        allow(relation).to receive(:size).with(no_args) { 3 }

        allow(relation).to receive(:each).and_yield(db1)
                                         .and_yield(db2)

        allow(builder).to receive(:call).with(criteria, db1) { 'entity1' }
        allow(builder).to receive(:call).with(criteria, db2) { 'entity2' }

        results = repo.load_collection(criteria, relation, builder)
        expect(results[:pager]).to be_an_instance_of(Appfuel::Pagination::Result)
        expect(results[:pager].total_pages).to eq 5
        expect(results[:pager].current_page).to eq 6
        expect(results[:pager].total_count).to eq 7
        expect(results[:pager].page_limit).to eq 8
        expect(results[:pager].page_size).to eq 3

        expect(results[:items]).to eq(['entity1', 'entity2'])
      end
    end

    context '#build_entities' do
      it 'builds an entity collection' do
        repo     = setup_mixin
        entity   = double('some entity')
        criteria = create_criteria('foo.bar')
        relation = double('some relation')
        builder  = double('some builder')

        allow_domain_type('foo.bar', entity)
        allow(repo).to receive(:create_entity_builder).with(criteria) { builder }
        results = repo.build_entities(criteria, relation)
        expect(results).to be_an_instance_of(Appfuel::Domain::EntityCollection)
        expect(results.entity_loader.lambda?).to be true
      end

      it 'returns the results from #handle_empty_dataset' do
        repo     = setup_mixin
        entity   = double('some entity')
        criteria = create_criteria('foo.bar')
        relation = double('some relation')
        builder  = double('some builder')

        allow_domain_type('foo.bar', entity)
        allow(relation).to receive(:blank?).with(no_args) { true }
        allow(repo).to receive(:create_entity_builder).with(criteria) { builder }
        allow(repo).to receive(:handle_empty_relation).with(criteria, relation) {
          'empty results'
        }
        results = repo.build_entities(criteria, relation)
        expect(results).to eq('empty results')
      end

      it 'returns a single entity' do
        repo     = setup_mixin
        entity   = double('some entity')
        criteria = create_criteria('foo.bar', single: true)
        relation = double('some relation')
        builder  = double('some builder')
        allow_domain_type('foo.bar', entity)
        allow(repo).to receive(:create_entity_builder).with(criteria) { builder }
        allow(builder).to receive(:call).with(criteria, relation) { 'single entity' }
        results = repo.build_entities(criteria, relation)
        expect(results).to eq('single entity')
      end
    end

    context '#query' do
      it 'return results from manual query when criteria uses "exec"' do
        repo     = setup_mixin
        criteria = create_criteria('foo.bar').exec('foo')

        def repo.foo_query(criteria)
        end

        allow(repo).to receive(:foo_query).with(criteria) { 'foo results' }
        results = repo.query(criteria)
        expect(results).to eq('foo results')
      end

      it 'returns the fully constructed domain' do
        repo     = setup_mixin
        criteria = create_criteria('foo.bar')
        relation = 'some relation'

        allow(repo).to receive(:query_relation).with(criteria) { relation }
        allow(repo).to receive(:handle_query_conditions).with(criteria, relation) { relation }
        allow(repo).to receive(:build_entities).with(criteria, relation) { 'the results' }

        results = repo.query(criteria)
        expect(results).to eq('the results')
      end
    end

    def setup_mixin
      repo = Object.new
      repo
    end
  end
end
