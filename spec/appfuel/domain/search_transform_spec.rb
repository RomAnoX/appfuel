module Appfuel::Domain
  RSpec.describe SearchTransform do

    context 'order_dir' do
      it 'transforms order_dir to "asc" slice "asc"' do
        expect(transform.apply(order_dir: 'asc')).to eq('asc')
      end

      it 'transforms order_dir from "ASC" slice to "asc"' do
        expect(transform.apply(order_dir: 'ASC')).to eq('asc')
      end

      it 'transforms order_dir to "desc" slice "desc"' do
        expect(transform.apply(order_dir: 'desc')).to eq('desc')
      end

      it 'transforms order_dir from "DESC" slice to "asc"' do
        expect(transform.apply(order_dir: 'DESC')).to eq('desc')
      end

      it 'transforms an empty order_dir into "asc"' do
        expect(transform.apply(order_dir: '')).to eq('asc')
      end

      it 'transforms any thing thats not "desc" into "asc"' do
        expect(transform.apply(order_dir: 'foo')).to eq('asc')
      end
    end

    context 'search' do
      it 'transforms search into a search criteria' do
        search = 'foo.bar filter role.id = 6 and id = 8 order id, role.id desc limit 7'
        tree   = parser.parse(search)
        result = transform.apply(tree)
        expect(result).to be_a(Hash)
        expect(result[:search]).to be_an_instance_of(SearchCriteria)

        expect(result[:search].domain_name).to eq('foo.bar')

        filters = result[:search].filters
        expect(filters).to be_an_instance_of(ExprConjunction)
        left  = 'features.foo.bar.role.id = 6'
        right = 'features.foo.bar.id = 8'
        expect(filters.left.to_s).to eq(left)
        expect(filters.right.to_s).to eq(right)

        order = result[:search].order_by
        expect(order).to be_a(Array)
        expect(order.size).to eq(2)
        expect(order[0].to_s).to eq('features.foo.bar.id asc')
        expect(order[1].to_s).to eq('features.foo.bar.role.id desc')
      end
    end

    def parse_failed_error
      Parslet::ParseFailed
    end

    def be_a_slice
      be_an_instance_of(slice)
    end

    def slice
      Parslet::Slice
    end

    def parser
      SearchParser.new
    end

    def transform
      SearchTransform.new
    end
  end
end
