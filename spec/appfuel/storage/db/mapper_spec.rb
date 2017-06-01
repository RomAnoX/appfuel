module Appfuel::Db
  RSpec.describe Mapper do
    context '#db_table_column' do
      it 'finds the entry and returns the db table and column' do
        app_name   = 'foo'
        entry      = double('some mapping entry')
        map        = {'baz.bar' => {'id' => entry}}
        db_key     = 'features.baz.db.biz'
        container  = double('some dependency container')
        db_class   = double('some active record model')
        table_name = 'biz'
        column     = 'biz_id'
        expr       = create_domain_expr(['features', 'baz', 'bar','id'], '=', 6)

        allow(Appfuel).to receive(:app_container).with(app_name) { container }
        allow(container).to receive(:[]).with(db_key) { db_class }
        allow(entry).to receive(:storage?).with(:db) { true }
        allow(entry).to receive(:storage).with(:db) { db_key }
        allow(entry).to receive(:container_name).with(no_args) { app_name }
        allow(db_class).to receive(:table_name).with(no_args) { table_name }
        allow(entry).to receive(:storage_attr).with(no_args) { column }

        mapper = create_mapper(app_name, map)
        result = mapper.db_table_column(expr)

        expect(result).to eq([table_name, column])
      end

      context '#qualified_db_column' do
        it 'creates a string in the form of table_name.column_name' do
          mapper = create_mapper('foo', {})
          expr   = create_domain_expr(['global', 'user','id'], '=', 6)
          allow(mapper).to receive(:db_table_column).with(expr, nil) {
            ["table", "column"]
          }

          result = "table.column"
          expect(mapper.qualified_db_column(expr)).to eq(result)
        end

        it 'passes on the entry to db_column_table' do
          mapper = create_mapper('foo', {})
          entry  = double('some mapping entry')

          expr   = create_domain_expr(['global', 'user','id'], '=', 6)
          expect(mapper).to receive(:db_table_column).with(expr, entry) {
            ["table", "column"]
          }

          mapper.qualified_db_column(expr, entry)
        end
      end

      context '#convert_expr' do
        it 'converts a domain expr into an array of string, values' do
          mapper = create_mapper('foo', {})
          expr   = create_domain_expr(['global', 'user','id'], '=', 6)
          allow(mapper).to receive(:qualified_db_column).with(expr, nil) {
            "user.id"
          }
          expect(mapper.convert_expr(expr)).to eq(['user.id = ?', 6])
        end

        it 'passes on the entry to convert_expr' do
          mapper = create_mapper('foo', {})
          entry  = double('some mapping entry')

          expr   = create_domain_expr(['global', 'user','id'], '=', 6)
          expect(mapper).to receive(:qualified_db_column).with(expr, entry)

          mapper.convert_expr(expr, entry)
        end
      end

      context '#exists?' do
        it 'converts domain expr into a db expr and call exists? on db model' do
          db_key   = 'global.db.user'
          db_class = double('some db class')
          table_name = 'user_account'
          allow(db_class).to receive(:table_name).with(no_args) { table_name }
          entry = create_entry({
            container: 'foo',
            domain_name: 'global.user',
            domain_attr: 'id',
            storage: {db: db_key},
            storage_attr: 'user_id'
          })

          map = {
            'global.user' => {
              'id' => entry
            }
          }

          expr   = create_domain_expr(['global', 'user','id'], '=', 6)
          mapper = create_mapper('foo', map)

          container = build_container(db_key => db_class)
          allow(Appfuel).to receive(:app_container).with('foo') { container }

          params = ["user_account.user_id = ?", 6]
          expect(db_class).to receive(:exists?).with(params) { true }
          expect(mapper.exists?(expr)).to be(true)
        end
      end

    end

    def create_entry(data)
      Appfuel::Repository::MappingEntry.new(data)
    end

    def create_domain_expr(list, op, value)
      Appfuel::Repository::Expr.new(list, op, value)
    end

    def create_mapper(app_name, map = {})
      Mapper.new(app_name, map)
    end
  end
end
