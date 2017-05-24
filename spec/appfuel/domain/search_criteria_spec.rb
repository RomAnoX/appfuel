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
    end
    def create_criteria(domain_name, settings = {})
      SearchCriteria.new(domain_name, settings)
    end
  end
end
