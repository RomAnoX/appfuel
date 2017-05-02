module Appfuel::Domain
  RSpec.describe Criteria do
    context 'initialize' do
      it 'creates a criteria with a feature name' do
        criteria = create_criteria('foo.bar')
        expect(criteria.feature).to eq 'foo'
      end

      it 'creates a criteria with a feature and domain' do
        criteria = create_criteria('foo.bar')
        expect(criteria.domain).to eq 'bar'
      end

      it 'creates a criteria with only a domain no feature' do
        criteria = create_criteria('bar')
        expect(criteria.domain).to eq 'bar'
      end

      it 'returns Types::Undefined for feature that is not defined' do
        criteria = create_criteria('bar')
        expect(criteria.feature).to eq nil
      end

      it 'returns feature when domain supports :domain_name' do
        domain = instance_double('Some Domain')
        allow(domain).to receive(:domain_name).with(no_args) { 'foo.bar' }
        criteria = create_criteria(domain)
        expect(criteria.feature).to eq 'foo'
        expect(criteria.domain).to eq 'bar'
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
        expect(create_criteria('foo').exprs).to be_empty
      end

      it 'is created with no Limit' do
        criteria = create_criteria('foo')
        expect(criteria.limit?).to be false
        expect(criteria.limit).to eq nil
      end

      it 'creates a criteria that will error on empty' do
        criteria = create_criteria('foo', error_on_empty: true)
        expect(criteria.error_on_empty_dataset?).to be true
      end

      it 'creates a criteria that will return a single entity' do
        criteria = create_criteria('foo', single: true)
        expect(criteria.single?).to be true
      end

      it 'creates a criteria with both error and single' do
        criteria = create_criteria('foo', single: true, error_on_empty: true)
        expect(criteria.single?).to be true
        expect(criteria.error_on_empty_dataset?).to be true
      end
    end

    context '#add_param' do
      let(:criteria) {create_criteria('foo', single: true, error_on_empty: true)}

      it 'returns nil if not param' do
        expect{ criteria.add_param(nil, nil) }.to raise_error('key should not be nil')
      end

      it 'returns the value added' do
        expect(criteria.add_param('my_key', 100)).to eq 100
      end

      it 'should added value' do
        value = 99
        criteria.add_param('my_key', value)

        expect(criteria.params?).to be_truthy
        expect(criteria.param(:my_key)).to eq value
        expect(criteria.param?(:my_key)).to be_truthy
      end
    end

    context '#filter' do
      let(:criteria) {create_criteria('foo', single: true, error_on_empty: true)}

      it 'raise an error if the filter is not an Array' do
        expect{ criteria.filter('foolish value') }.to raise_error(RuntimeError, 'the attribute must be an Array')
      end

      it 'raise an error if the filters are not Hashes' do
        expect{ criteria.filter([[3,4],5]) }.to raise_error(RuntimeError, 'filters must be a Hash')
      end

      it 'return [] if the array is empty' do
        expect( criteria.filter([]) ).to eq []
      end

      it 'return a cleaned list of filters' do
        filters = [
          {'foo.bar.id': 1},
          {first_name: 'Sarah', op: :eq, or: true},
          {last_name: 'Bits', op: :eq, or: true}
        ]

        criteria_filter = criteria.filter(filters)

        expect(criteria_filter).to_not be_nil
        expect(criteria_filter).to eq([
          {'foo.bar.id': 1},
          {first_name: 'Sarah'},
          {last_name: 'Bits'}
        ])
      end
    end

    context '#feature?' do
      it 'returns true when a feature was given' do
        criteria = create_criteria('foo.bar')
        expect(criteria.feature?).to be true
      end

      it 'returns false when no feature is given' do
        criteria = create_criteria('bar')
        expect(criteria.feature?).to be false
      end
    end

    context '#global_domain?' do
      it 'returns false when a feature is defined' do
        criteria = create_criteria('foo.bar')
        expect(criteria.global_domain?).to be false
      end

      it 'returns true when a feature is not defined' do
        criteria = create_criteria('bar')
        expect(criteria.global_domain?).to be true
      end
    end

    context '#where' do
      let(:criteria) { create_criteria('foo') }

      it 'adds an expr to the list' do
        criteria.where(:id, eq: 4)
        expect(criteria.exprs.size).to eq 1
      end

      it 'creates an EntityExpr with domain_attr operator and value' do
        criteria.where(:id, eq: 4)
        result = criteria.exprs.first
        expect(result).to be_a(Hash)
        expect(result.key?(:expr)).to be true
        expect(result.key?(:relational_op)).to be true

        expr = result[:expr]
        op   = result[:relational_op]

        expect(op).to eq :and
        expect(expr).to be_an_instance_of(Expr)
        expect(expr.domain_attr).to eq "id"
        expect(expr.op).to eq :eq
        expect(expr.value).to eq 4
      end
    end

    context '#limit' do
      let(:criteria) { create_criteria('foo') }

      it 'adds a limit for the criteria' do
        criteria.limit(6)
        expect(criteria.limit?).to be true
        expect(criteria.limit).to eq 6
      end

      it 'fails if the limit is zero' do
        expect{ criteria.limit(0) }.to raise_error("limit must be an integer gt 0")
      end
    end

    context '#order_by' do
      it 'adds a order for an attribute defaults to asc' do
        criteria = create_criteria('foo')
        criteria.order_by(:id)
        expect(criteria.order.first).to be_an_instance_of(Expr)
        expr = criteria.order.first
        expect(expr.domain_name).to eq(criteria.domain_name)
        expect(expr.domain_attr).to eq('id')
        expect(expr.value).to eq('ASC')
      end

      it 'adds and order by attr that is desc' do
        criteria = create_criteria('foo')
        criteria.order_by(:id, :desc)
        expect(criteria.order.first).to be_an_instance_of(Expr)

        expr = criteria.order.first
        expect(expr.domain_name).to eq(criteria.domain_name)
        expect(expr.domain_attr).to eq('id')
        expect(expr.value).to eq('DESC')
      end
    end

    context '#or' do
      it 'assigns a entity expr with a logical or operator' do
        criteria = create_criteria('foo')
        criteria.where(:id, eq: 4).or(:id, eq: 5)
        expect(criteria.exprs.size).to eq 2

        result     = criteria.exprs
        first_expr = result.first
        last_expr  = result.last

        expect(first_expr[:relational_op]).to eq :and

        expr = last_expr[:expr]
        op   = last_expr[:relational_op]

        expect(op).to eq :or
        expect(expr).to be_an_instance_of(Expr)
        expect(expr.domain_attr).to eq "id"
        expect(expr.op).to eq :eq
        expect(expr.value).to eq 5
      end
    end

    context '#exec' do
      let(:criteria) {create_criteria('foo')}

      it 'there is no exec method name by default' do
        expect(criteria.exec).to eq nil
      end

      it 'determines there is no exec by default' do
        expect(criteria.exec?).to be false
      end

      it 'assigns a method name to be executed by the repo' do
        criteria.exec :my_method
        expect(criteria.exec).to eq :my_method
      end

      it 'determines that the exec has been assigned' do
        criteria.exec :my_method
        expect(criteria.exec?).to be true
      end
    end

    context '#page' do
      it 'has a default page determined by the criteria' do
        criteria = Criteria('foo')
        expect(criteria.page).to eq(criteria.class::DEFAULT_PAGE)
      end

      it 'assigns a page value to the criteria for pagination' do
        criteria = Criteria('foo')
        criteria.page(11)
        expect(criteria.page).to eq 11
      end

      it 'returns an instance of the criteria to be chained' do
        criteria = Criteria('foo')
        expect(criteria.page(22)).to eq criteria
      end
    end

    context '#per_page' do
      it 'has a default per_page determined by the criteria' do
        criteria = Criteria('foo')
        expect(criteria.per_page).to eq(criteria.class::DEFAULT_PER_PAGE)
      end

      it 'assigns a per_page value to the criteria' do
        criteria = Criteria('foo')
        criteria.per_page(99)
        expect(criteria.per_page).to eq 99
      end

      it 'returns an instance of the criteria to be chained' do
        criteria = Criteria('foo')
        expect(criteria.per_page(22)).to eq criteria
      end
    end

    context '#each' do
      let(:criteria) { create_criteria('foo') }

      it 'return enumerator' do
        filter = [{last_name: 'SirFooish', op: 'like', or: true}, {first_name: 'Bob', op: 'like', or: true}]

        criteria.filter(filter)
        expect(criteria.each.class).to eq Enumerator
      end
    end
  end
end
