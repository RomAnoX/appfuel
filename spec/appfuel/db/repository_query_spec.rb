module Appfuel::Db
  RSpec.describe RepositoryQuery do

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
      it 'creates an entity not found null object for the criteria domain' do
        domain = double(Appfuel::Domain::Entity)
        allow_domain_type('foo.bar', domain)
        allow(domain).to receive(:new).with({})

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

      it 'return entity not found when criteria expects a single entity' do
        repo      = setup_mixin
        criteria  = create_criteria('foo.bar', single: true)
        relation  = double('some relation')
        domain    = double(Appfuel::Domain::Entity)
        not_found = double('some not found entity')

        allow_domain_type('foo.bar', domain)
        allow(relation).to receive(:blank?).with(no_args) { true }
        allow(domain).to receive(:new).with({}) { not_found }

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
      it 'delegates to where, order, and limit' do
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
      it "delegates to the relation's :all and limit interfaces" do
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

    def setup_mixin
      repo = Object.new
      repo.extend(Appfuel::RootModule)
      repo.extend(Mapper)
      repo.extend(RepositoryQuery)
      repo
    end
  end
end
