module Appfuel::Domain
  RSpec.describe ExprTransform do

    context 'values' do
      it 'transforms a integer' do
        expect(transform.apply(integer: "1")).to eq(1)
      end

      it 'transforms a float' do
        expect(transform.apply(float: "1.23")).to eq(1.23)
      end

      it 'transforms a boolean false' do
        expect(transform.apply(boolean: "false")).to eq(false)
      end

      it 'transforms a boolean FALSE' do
        expect(transform.apply(boolean: "FALSE")).to eq(false)
      end

      it 'transforms a boolean true' do
        expect(transform.apply(boolean: "true")).to eq(true)
      end

      it 'transforms a boolean FALSE' do
        expect(transform.apply(boolean: "TRUE")).to eq(true)
      end

      it 'transforms a date' do
        value  = '2017-01-01'
        result = transform.apply(date: value)
        expect(result).to eq(Date.parse(value))
      end

      it 'transforms a datetime' do
        value  = '2017-01-01T07:32:00Z'
        result = transform.apply(datetime: value)
        expect(result).to eq(Time.parse(value))
      end

      it 'transforms a string' do
        expect(transform.apply(string: "foo bar baz")).to eq("foo bar baz")
      end

      it 'transforms special characters in captured strings' do
        expect(transform.apply(string: "a\\nb")).to eq("a\nb")
      end
    end

    context 'domain_expr' do
      it 'transforms a domain expr' do
        expr = parser.parse('id = 6')
        result = transform.apply(expr)
        domain_expr = result[:domain_expr]
        expect(domain_expr).to be_an_instance_of(Expr)
        expect(domain_expr.value).to eq(6)
        expect(domain_expr.op).to eq("=")
        expect(domain_expr.attr_list).to eq(['id'])
      end
    end

    context 'conjunction' do
      it 'transforms an and conjunction' do
        expr = parser.parse('id = 6 and bar = "foo"')
        result = transform.apply(expr)
        conjunction = result[:root]
        expect(conjunction).to be_an_instance_of(ExprConjunction)
        expect(conjunction.op).to eq("and")
        expect(conjunction.left.value).to eq(6)
        expect(conjunction.right.value).to eq("foo")
      end

      it 'transforms an or conjunction' do
        expr = parser.parse('id = 6 or bar = "foo"')
        result = transform.apply(expr)
        conjunction = result[:root]
        expect(conjunction).to be_an_instance_of(ExprConjunction)
        expect(conjunction.op).to eq("or")
        expect(conjunction.left.value).to eq(6)
        expect(conjunction.right.value).to eq("foo")
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
      ExprParser.new
    end

    def transform
      ExprTransform.new
    end
  end
end
