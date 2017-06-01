module Appfuel::Repository
  RSpec.describe Criteria do
    context 'initialize' do
      it 'creates a criteria with a feature name' do
        criteria = create_criteria('foo.bar')
        expect(criteria.feature).to eq 'foo'
      end

      it 'creates a criteria with a feature and domain' do
        criteria = create_criteria('foo.bar')
        expect(criteria.domain_basename).to eq 'bar'
      end

      it 'fails when domain_name has no feature or global component' do
        msg = 'domain names must be in the form of (<feature|global>.domain)'
        expect {
          create_criteria('bar')
        }.to raise_error(msg)
      end

      it 'returns feature when domain supports :domain_name' do
        domain = instance_double('Some Domain')
        allow(domain).to receive(:domain_name).with(no_args) { 'foo.bar' }
        criteria = create_criteria(domain)
        expect(criteria.feature).to eq 'foo'
        expect(criteria.domain_basename).to eq 'bar'
      end

      it 'fails when domain is not a string' do
        msg = 'domain name must be a string or implement method :domain_name'
        expect {
          create_criteria(12345)
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when domain nil' do
        msg = 'domain name must be a string or implement method :domain_name'
        expect {
          create_criteria(nil)
        }.to raise_error(RuntimeError, msg)
      end

      it 'is created with empty expr list' do
        expect(create_criteria('foo.bar').filters).to eq(nil)
      end
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
        expect(criteria.order_by).to eq([])
      end
    end

    context '#global?' do
      it 'returns true when domain is a global domain' do
        criteria = create_criteria('global.user')
        expect(criteria.global?).to be true
      end

      it 'returns false when domain is a feature domain' do
        criteria = create_criteria('membership.user')
        expect(criteria.global?).to be false
      end
    end

    context '#feature?' do
      it 'return true when domain belongs to a feature' do
        criteria = create_criteria('membership.user')
        expect(criteria.feature?).to be true
      end

      it 'returns false for a global domain' do
        criteria = create_criteria('global.user')
        expect(criteria.feature?).to be false
      end
    end

    context '#add_param' do

      it 'returns nil if not param' do
        expect {
          create_criteria('foo.bar').add_param(nil, nil)
        }.to raise_error('key should not be nil')
      end

      it 'returns the value added' do
        result = create_criteria('foo.bar').add_param('my_key', 100)
        expect(result).to eq 100
      end

      it 'should added value' do
        value = 99
        criteria = create_criteria('foo.bar')
        criteria.add_param('my_key', value)

        expect(criteria.params?).to be_truthy
        expect(criteria.param(:my_key)).to eq value
        expect(criteria.param?(:my_key)).to be_truthy
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

        expect(criteria.order_by.size).to eq(1)
        expect(result).to eq(criteria)

        expr = criteria.order_by[0]
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

        expect(criteria.order_by.size).to eq(2)
        expect(result).to eq(criteria)

        expr1 = criteria.order_by[0]
        expect(expr1).to be_an_instance_of(OrderExpr)
        expect(expr1.qualified?).to be(true)
        expect(expr1.to_s).to eq('features.foo.bar.id asc')

        expr2 = criteria.order_by[1]
        expect(expr2).to be_an_instance_of(OrderExpr)
        expect(expr2.qualified?).to be(true)
        expect(expr2.to_s).to eq('features.foo.bar.code desc')
      end
    end

    def create_criteria(domain_name, settings = {})
      Criteria.new(domain_name, settings)
    end
  end
end
