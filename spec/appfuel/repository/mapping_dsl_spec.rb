module Appfuel::Repository
  RSpec.describe MappingDsl do
    context '#initialize' do
      it 'creates an empty map' do
        expect(create_dsl('foo', 'bar').entries).to eq([])
      end

      it 'assigns the entity name as a string' do
        expect(create_dsl('foo', 'bar').domain_name).to eq 'foo'
      end

      it 'assigns the storage as a hash with db: bar' do
        result = {
          db: 'global.storage.db.bar'
        }
        expect(create_dsl('foo', 'global.bar').storage).to eq(result)
      end

      it 'fails when db name is empty' do
        msg = 'db can not be empty'
        expect {
          create_dsl("foo", '')
        }.to raise_error(RuntimeError, msg)
      end

      context '#initialize storage keys' do
        it 'converts partial feature storage key to qualified container keys' do
          options = {
            db: 'foo.some_db_class',
            yaml: 'foo.some_yaml_class'
          }
          dsl = create_dsl('foo', options)
          expected_storage = {
            db: 'features.foo.storage.db.some_db_class',
            yaml: 'features.foo.storage.yaml.some_yaml_class'
          }

          expect(dsl.storage).to eq(expected_storage)
        end

        it 'converts global keys to the correct container namespace' do
          options = {
            db: 'global.some_db_class',
            yaml: 'global.some_yaml_class'
          }
          dsl = create_dsl('foo', options)
          expected_storage = {
            db: 'global.storage.db.some_db_class',
            yaml: 'global.storage.yaml.some_yaml_class'
          }

          expect(dsl.storage).to eq(expected_storage)
        end
      end
    end

    context '#map' do
      it 'maps storage attr to attributes as strings' do
        dsl = create_dsl('foo', 'global.bar')
        data = {
          domain_name: 'foo',
          domain_attr: 'id',
          storage: {db: 'global.storage.db.bar'},
          storage_attr: 'bar_id',
          container: nil
        }
        expect_new_mapping_entry(data)
        dsl.map 'bar_id', 'id'
      end

      it 'maps a computed property' do
        value = -> {'foo'}
        dsl = create_dsl('foo', 'bar.baz')
        data = {
          domain_name: 'foo',
          domain_attr: 'created_at',
          storage: {db: 'features.bar.storage.db.baz'},
          storage_attr: 'created_at',
          computed_attr: value,
          container: nil
        }
        expect_new_mapping_entry(data)
        dsl.map 'created_at', 'created_at', computed_attr: value
      end

      it 'maps a column that will skip all' do
        dsl = create_dsl('foo', db: 'global.bar')
        data = {
          domain_name: 'foo',
          domain_attr: 'blah',
          storage: {db: 'global.storage.db.bar'},
          storage_attr: 'bar_blah',
          skip: true,
          container: nil
        }
        expect_new_mapping_entry(data)
        dsl.map 'bar_blah', 'blah', skip: true
      end

      it 'assigns the container these maps belong to' do
        dsl = create_dsl('foo', db: 'global.bar', container: 'fooish')
        data = {
          domain_name: 'foo',
          domain_attr: 'blah',
          storage: {db: 'global.storage.db.bar'},
          storage_attr: 'bar_blah',
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
