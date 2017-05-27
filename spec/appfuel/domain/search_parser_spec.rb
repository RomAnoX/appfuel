module Appfuel::Domain
  RSpec.describe ExprParser do

    context 'order_identifier' do
      it 'parses order' do
        expect(parser.order_identifier.parse('order')).to be_a_slice
      end

      it 'parses order uppercase' do
        expect(parser.order_identifier.parse('ORDER')).to be_a_slice
      end

      it 'fails when not order keyword' do
        msg = "Failed to match sequence ([Oo] [Rr] [Dd] [Ee] [Rr]) " +
              "at line 1 char 5."
        expect {
          parser.order_identifier.parse('orders')
        }.to raise_error(msg)
      end
    end

    context 'filter_identifier' do
      it 'parses filter' do
        expect(parser.filter_identifier.parse('filter')).to be_a_slice
      end

      it 'parses filter uppercase' do
        expect(parser.filter_identifier.parse('FILTER')).to be_a_slice
      end

      it 'fails when not filter' do
        msg = "Failed to match sequence ([Ff] [Ii] [Ll] [Tt] [Ee] [Rr]) " +
              "at line 1 char 6."
        expect {
          parser.filter_identifier.parse('FILTERS')
        }.to raise_error(msg)
      end
    end

    context 'limit_identifier' do
      it 'parses limit' do
        expect(parser.limit_identifier.parse('limit')).to be_a_slice
      end

      it 'parses limit uppercase' do
        expect(parser.limit_identifier.parse('LIMIT')).to be_a_slice
      end

      it 'fails when not filter' do
        msg = "Failed to match sequence ([Ll] [Ii] [Mm] [Ii] [Tt]) " +
              "at line 1 char 5."
        expect {
          parser.limit_identifier.parse('LIMITS')
        }.to raise_error(msg)
      end
    end

    context 'limit_expr' do
      it 'parses a "limit 9"' do
        result = parser.limit_expr.parse('limit 9')
        expect(result).to be_a(Hash)
        expect(result[:limit]).to be_a(Hash)
        expect(result[:limit][:value][:integer]).to be_a_slice
        expect(result[:limit][:value][:integer].to_s).to eq('9')
      end

      it 'fails to parse limit with no integer' do
        msg = "Failed to match sequence " +
              "(LIMIT_IDENTIFIER SPACE SPACE? value:INTEGER) " +
              "at line 1 char 7."
        expect {
          parser.limit_expr.parse('limit ')
        }.to raise_error(msg)
      end
    end

    context 'order_dir' do
      it 'parses "asc"' do
        result = parser.order_dir.parse('asc')
        expect(result[:order_dir]).to be_a_slice
        expect(result[:order_dir].to_s).to eq('asc')
      end

      it 'parses "ASC"' do
        result = parser.order_dir.parse('ASC')
        expect(result[:order_dir]).to be_a_slice
        expect(result[:order_dir].to_s).to eq('ASC')
      end
      it 'parses "desc"' do
        result = parser.order_dir.parse('desc')
        expect(result[:order_dir]).to be_a_slice
        expect(result[:order_dir].to_s).to eq('desc')
      end

      it 'parses "DESC"' do
        result = parser.order_dir.parse('DESC')
        expect(result[:order_dir]).to be_a_slice
        expect(result[:order_dir].to_s).to eq('DESC')
      end

      it 'fails when not asc|desc' do
        msg = "Expected one of [[Aa] [Ss] [Cc], [Dd] [Ee] [Ss] [Cc]] " +
              "at line 1 char 1."
        expect {
         parser.order_dir.parse('foo')
        }.to raise_error(msg)
      end
    end

    context 'order_expr' do
      it 'parses an regular domain_attr' do
        result = parser.order_expr.parse('id')
        expect(result[:order_expr]).to be_a(Hash)

        result = result[:order_expr]
        expect(result[:domain_attr][:attr_label].to_s).to eq('id')
      end

      it 'parses "id asc"' do
        result = parser.order_expr.parse('id asc')
        expect(result[:order_expr][:domain_attr][:attr_label].to_s).to eq('id')
        expect(result[:order_expr][:order_dir].to_s).to eq('asc')
      end


      it 'parses "foo.id asc"' do
        result = parser.order_expr.parse('foo.id asc')

        result = result[:order_expr]
        expect(result[:domain_attr][0][:attr_label].to_s).to eq('foo')
        expect(result[:domain_attr][1][:attr_label].to_s).to eq('id')
        expect(result[:order_dir].to_s).to eq('asc')
      end
    end

    context 'order_by' do
      it 'parses "order id asc, foo.id desc, bar"' do
        result = parser.order_by.parse('order id asc, foo.id desc, bar')
        expect(result[:order]).to be_a(Hash)

        order = result[:order]
        expect(order[:list]).to be_a(Array)

        list = order[:list]
        expect(list.size).to eq(3)
        expect(list[0][:order_expr][:domain_attr][:attr_label].to_s).to eq('id')
        expect(list[0][:order_expr][:order_dir].to_s).to eq('asc')

        domain_attr = list[1][:order_expr][:domain_attr]
        expect(domain_attr[0][:attr_label].to_s).to eq('foo')
        expect(domain_attr[1][:attr_label].to_s).to eq('id')
        expect(list[1][:order_expr][:order_dir].to_s).to eq('desc')

        expect(list[2][:order_expr][:domain_attr][:attr_label].to_s).to eq('bar')
      end
    end
    context 'domain_name' do
      it 'parses a domain_name in the form of "feature.domain"' do
        result = parser.domain_name.parse('foo.bar')
        expect(result).to be_a(Hash)
        expect(result[:feature][:attr_label]).to be_a_slice
        expect(result[:feature][:attr_label].to_s).to eq('foo')
        expect(result[:basename][:attr_label]).to be_a_slice
        expect(result[:basename][:attr_label].to_s).to eq('bar')
      end
    end

    context 'search' do
      it 'parses a search string' do
        parser.parse('foo.bar filter id = 6')
      end
    end

    def space_error_msg
      'Expected at least 1 of \\\\s at line 1 char 1.'
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
  end
end
