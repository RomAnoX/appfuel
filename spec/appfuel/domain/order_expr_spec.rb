module Appfuel::Domain
  RSpec.describe OrderExpr do
    context '#initialize' do
      it 'creates an order expr where the op is "asc" by default' do
        expect(order_expr_class.new('foo.bar.id').op).to eq('asc')
      end

      it 'assign the domain attribute' do
        expr = create_expr('foo.bar.id', 'asc')
        expect(expr.attr_list).to eq(['foo', 'bar', 'id'])
      end

      it 'assigns the direction of the order as desc' do
        expr = create_expr('foo.bar.id', 'desc')
        expect(expr.op).to eq('desc')
      end

      it 'assigns the direction of the order as lowercase' do
        expr = create_expr('foo.bar.id', 'DESC')
        expect(expr.op).to eq('desc')
      end
    end

    context '#to_s' do
      it 'creates a string in the form of [domain_attr <dir>]' do
        expr = create_expr('foo.bar.id', 'desc')
        expect(expr.to_s).to eq('foo.bar.id desc')
      end
    end

    context '.build' do
      it 'builds a basic string as an order expr' do
        result = order_expr_class.build('foo.bar.id desc')
        expect(result).to be_an(Array)
        expect(result.size).to eq(1)
        expect(result[0].to_s).to eq('foo.bar.id desc')
      end

      it 'builds an array of strings' do
        data = [
          'foo.bar.id desc',
          'foo.id asc',
          'code'
        ]
        result = order_expr_class.build(data)
        expect(result).to be_an(Array)
        expect(result.size).to eq(3)
        expect(result[0].to_s).to eq('foo.bar.id desc')
        expect(result[1].to_s).to eq('foo.id asc')
        expect(result[2].to_s).to eq('code asc')
      end

      it 'builds an array of strings and hashes' do
        data = [
          {'foo.bar.id' => 'desc'},
          'foo.id asc',
          {'code' => 'asc'}
        ]
        result = order_expr_class.build(data)
        expect(result).to be_an(Array)
        expect(result.size).to eq(3)
        expect(result[0].to_s).to eq('foo.bar.id desc')
        expect(result[1].to_s).to eq('foo.id asc')
        expect(result[2].to_s).to eq('code asc')
      end
    end

    def order_expr_class
      OrderExpr
    end

    def create_expr(domain_attr, op)
      order_expr_class.new(domain_attr, op)
    end
  end
end
