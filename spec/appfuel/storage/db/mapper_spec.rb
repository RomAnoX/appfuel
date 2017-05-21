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

        allow(Appfuel).to receive(:app_container).with(app_name) { container }
        allow(container).to receive(:[]).with(db_key) { db_class }
        allow(entry).to receive(:storage?).with(:db) { true }
        allow(entry).to receive(:storage).with(:db) { db_key }
        allow(entry).to receive(:container_name).with(no_args) { app_name }
        allow(db_class).to receive(:table_name).with(no_args) { table_name }
        allow(entry).to receive(:storage_attr).with(no_args) { column }
        mapper = create_mapper(app_name, map)
        expr   = create_domain_expr(['features', 'baz', 'bar','id'], '=', 6)

        result = mapper.db_table_column(expr)

        expect(result).to eq([table_name, column])
      end
    end

    def create_domain_expr(list, op, value)
      Appfuel::Domain::Expr.new(list, op, value)
    end

    def create_mapper(app_name, map = {})
      Mapper.new(app_name, map)
    end
  end
end
