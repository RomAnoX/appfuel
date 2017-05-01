module Appfuel::Repository
  RSpec.describe MappingDsl do
    before(:each) do
      setup(app_name: 'foo')
    end

    context '#initialize' do

      it 'creates an empty map' do
        expect(create_dsl('foo', 'bar').entries).to eq([])
      end

      it 'assigns the entity name as a string' do
        expect(create_dsl('foo', 'bar').domain_name).to eq 'foo'
      end

      it 'translate the db model using the global domain_name"' do
        result = {
          db: 'global.storage.db.bar'
        }
        expect(create_dsl('global.bar', db: true).storage).to eq(result)
      end

      it 'translate the db model using the feature domain_name"' do
        result = {
          db: 'features.foo.storage.db.bar'
        }
        expect(create_dsl('foo.bar', db: true).storage).to eq(result)
      end


      it 'translates the global db model using the given key' do
        result = {
          db: 'global.storage.db.fiz'
        }
        expect(create_dsl('global.bar', db: 'global.fiz').storage).to eq(result)
      end

      it 'translates the feature db model using the given key' do
        result = {
          db: 'features.foo.storage.db.bar'
        }
        expect(create_dsl('foo.fooish', db: 'foo.bar').storage).to eq(result)
      end


      it 'translates the db model using a manual key' do
        key = 'fiz.biz.baz.bam'
        result = {
          db: key
        }
        options = { db: key, key_translation: false }
        expect(create_dsl('foo.fooish', options).storage).to eq(result)
      end

      it 'translates storage [:db, :file] using default feature keys' do
        storage_path = '/some/path/to/storage'
        container = Appfuel.app_container('foo')
        container.register(:root_path, '/my/root/path')
        container.register(:storage_path, storage_path)

        result = {
          db: 'features.foo.storage.db.fooish',
          file: {
            model: 'storage.file.model',
            path: "#{storage_path}/features/foo/storage/file/fooish.yml"
          }
        }
        dsl = create_dsl('foo.fooish', storage: [:db, :file])

        expect(dsl.storage).to eq(result)
      end

      it 'fails when db name is empty' do
        msg = 'db can not be empty'
        expect {
          create_dsl("foo", '')
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#map' do
      it 'maps storage attr to attributes as strings' do
        dsl = create_dsl('foo', db: 'global.bar')
        data = {
          domain_name: 'foo',
          domain_attr: 'id',
          storage: {db: 'global.storage.db.bar'},
          storage_attr: 'bar_id',
          container: "foo" # note setup assign default app name
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
          container: "foo" # note setup assign default app name
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
          container: "foo" # note setup assign default app name
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

    def setup(app_name:, data: {})
      container = build_container(data)
      Appfuel.framework_container.register(:default_app_name, app_name)
      Appfuel.framework_container.register(app_name, container)
    end

    def expect_new_mapping_entry(inputs)
      expect(MappingEntry).to receive(:new).with(inputs)
    end

    def create_dsl(domain_name, options)
      MappingDsl.new(domain_name, options)
    end
  end
end
