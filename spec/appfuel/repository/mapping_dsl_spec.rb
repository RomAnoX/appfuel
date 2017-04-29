module Appfuel::Repository
  RSpec.describe MappingDsl do
    context '#initialize' do
      it 'creates an empty map' do
        expect(create_dsl('foo', 'bar').entries).to eq([])
      end

      it 'assigns the entity name as a string' do
        expect(create_dsl('foo', 'bar').domain_name).to eq 'foo'
      end

      it 'assigns the persistence as a hash with db: bar' do
        expect(create_dsl('foo', 'bar').persistence).to eq({db: 'bar'})
      end

      it 'fails when db name is empty' do
        msg = 'db can not be empty'
        expect {
          create_dsl("foo", '')
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#map' do
      it 'maps persistence attr to attributes as strings' do
        dsl = create_dsl('foo', 'bar')
        data = {
          domain_name: 'foo',
          domain_attr: 'id',
          persistence: {db: 'bar'},
          persistence_attr: 'bar_id',
          container: nil
        }
        expect_new_mapping_entry(data)
        dsl.map 'bar_id', 'id'
      end

      it 'maps a computed property' do
        value = -> {'foo'}
        dsl = create_dsl('foo', 'bar')
        data = {
          domain_name: 'foo',
          domain_attr: 'created_at',
          persistence: {db: 'bar'},
          persistence_attr: 'created_at',
          computed_attr: value,
          container: nil
        }
        expect_new_mapping_entry(data)
        dsl.map 'created_at', 'created_at', computed_attr: value
      end

      it 'maps a column that will skip all' do
        dsl = create_dsl('foo', db: 'bar')
        data = {
          domain_name: 'foo',
          domain_attr: 'blah',
          persistence: {db: 'bar'},
          persistence_attr: 'bar_blah',
          skip: true,
          container: nil
        }
        expect_new_mapping_entry(data)
        dsl.map 'bar_blah', 'blah', skip: true
      end

      it 'assigns the container these maps belong to' do
        dsl = create_dsl('foo', db: 'bar', container: 'fooish')
        data = {
          domain_name: 'foo',
          domain_attr: 'blah',
          persistence: {db: 'bar'},
          persistence_attr: 'bar_blah',
          container: 'fooish'
        }
        expect_new_mapping_entry(data)
        dsl.map 'bar_blah', 'blah'
      end
    end

    def expect_new_mapping_entry(inputs)
      expect(MappingEntry).to receive(:new).with(inputs)
    end

    def create_dsl(domain_name, options)
      MappingDsl.new(domain_name, options)
    end
  end
end
