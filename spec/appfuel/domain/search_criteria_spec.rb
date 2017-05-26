module Appfuel::Domain
  RSpec.describe BaseCriteria do
    context 'initialize' do
      it 'initializes with no expressions when given no args' do
        criteria = create_criteria('foo.bar')
        expect(criteria.filters?).to be false
      end

      it 'defaults to no limit' do
        criteria = create_criteria('foo.bar')
        expect(criteria.limit).to eq(nil)
      end

      it 'defaults to an empty list of order expressions' do
        criteria = create_criteria('foo.bar')
        expect(criteria.order_exprs).to eq([])
      end
    end

    context '#filter' do
      it 'assigns a basic domain expr for a filter' do
        criteria = create_criteria('foo.bar')
        criteria.filter('id = 6')
        expr = criteria.filters
        expect(expr).to be_instance_of(Expr)
        expect(expr.value).to eq(6)
        expect(expr.op).to eq('=')
        expect(expr.attr_list).to eq(['features', 'foo', 'bar', 'id'])
      end

      it 'assigns a conjunction expr for a filter, no other filters assigned' do
        criteria = create_criteria('foo.bar')
        criteria.filter('id = 6 and status = "active"')
        expr = criteria.filters
        expect(expr).to be_instance_of(ExprConjunction)

        list = ['features', 'foo', 'bar']
        id_attr = list + ['id']
        status_attr = list + ['status']

        expect(expr.left.attr_list).to eq(id_attr)
        expect(expr.right.attr_list).to eq(status_attr)
      end

      it 'builds a conjunction from an existing expr' do
        criteria = create_criteria('foo.bar')
        criteria.filter('id = 6').filter('id = 9')

        expr = criteria.filters
        expect(expr).to be_instance_of(ExprConjunction)
        expect(expr.left.value).to eq(6)
        expect(expr.right.value).to eq(9)
      end
    end

    context '#limit' do
      it 'returns nil when no limit has been set' do
        expect(create_criteria('foo.bar').limit).to eq(nil)
      end

      it 'assigns the limit and returns itself' do
        criteria = create_criteria('foo.bar')
        result = criteria.limit(6)
        expect(criteria.limit).to eq(6)
        expect(result).to eq(criteria)
      end

      it 'fails when limit is not an integer' do
        criteria = create_criteria('foo.bar')
        msg = 'invalid value for Integer(): "abc"'
        expect {
          criteria.limit('abc')
        }.to raise_error(msg)
      end
    end

    context '#order' do
      it 'accepts a string as an order expr' do
        criteria = create_criteria('foo.bar')
        result = criteria.order('id asc')

        expect(criteria.order_exprs.size).to eq(1)
        expect(result).to eq(criteria)

        expr = criteria.order_exprs[0]
        expect(expr).to be_an_instance_of(OrderExpr)
        expect(expr.qualified?).to be(true)
        expect(expr.to_s).to eq('features.foo.bar.id asc')
      end

      it 'accepts an array of order strings or hashes' do
        data = [
          'id asc',
          {'code' => 'desc'}
        ]
        criteria = create_criteria('foo.bar')
        result = criteria.order(data)

        expect(criteria.order_exprs.size).to eq(2)
        expect(result).to eq(criteria)

        expr1 = criteria.order_exprs[0]
        expect(expr1).to be_an_instance_of(OrderExpr)
        expect(expr1.qualified?).to be(true)
        expect(expr1.to_s).to eq('features.foo.bar.id asc')

        expr2 = criteria.order_exprs[1]
        expect(expr2).to be_an_instance_of(OrderExpr)
        expect(expr2.qualified?).to be(true)
        expect(expr2.to_s).to eq('features.foo.bar.code desc')
      end
    end


    def create_criteria(domain_name, settings = {})
      SearchCriteria.new(domain_name, settings)
    end
  end
end
