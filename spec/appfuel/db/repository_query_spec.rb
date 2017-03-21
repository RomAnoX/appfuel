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
        msg  = 'Could not execute domain query method my_domain_query'
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

    def setup_mixin
      repo = Object.new
      repo.extend(RepositoryQuery)
      repo
    end
  end
end
