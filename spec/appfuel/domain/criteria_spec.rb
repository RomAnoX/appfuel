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
      it 'adds an expr to the list' do
        criteria = create_criteria('foo')
        criteria.where(:id, eq: 4)
        expect(criteria.exprs.size).to eq 1
      end

      it 'creates an EntityExpr with attr operator and value' do
        criteria = create_criteria('foo')
        criteria.where(:id, eq: 4)
        result = criteria.exprs.first
        expect(result).to be_a(Hash)
        expect(result.key?(:expr)).to be true
        expect(result.key?(:op)).to be true

        expr = result[:expr]
        op   = result[:op]

        expect(op).to eq :and
        expect(expr).to be_an_instance_of(Expr)
        expect(expr.attr).to eq "id"
        expect(expr.op).to eq :eq
        expect(expr.value).to eq 4
      end
    end

    context '#limit' do
      it 'adds a limit for the criteria' do
        criteria = create_criteria('foo')
        criteria.limit(6)
        expect(criteria.limit?).to be true
        expect(criteria.limit).to eq 6
      end
    end

    context '#order_by' do
      it 'adds a order for an attribute defaults to asc' do
        criteria = create_criteria('foo')
        criteria.order_by(:id)
        expect(criteria.order).to eq({id: :asc})
      end

      it 'adds and order by attr that is desc' do
        criteria = create_criteria('foo')
        criteria.order_by(:id, :desc)
        expect(criteria.order).to eq({id: :desc})
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

        expect(first_expr[:op]).to eq :or

        expr = last_expr[:expr]
        op   = last_expr[:op]

        expect(op).to eq :and
        expect(expr).to be_an_instance_of(Expr)
        expect(expr.attr).to eq "id"
        expect(expr.op).to eq :eq
        expect(expr.value).to eq 5
      end
    end

    context '#exec' do
      it 'there is no exec method name by default' do
        criteria = create_criteria('foo')
        expect(criteria.exec).to eq nil
      end

      it 'determines there is no exec by default' do
        criteria = create_criteria('foo')
        expect(criteria.exec?).to be false
      end

      it 'assigns a method name to be executed by the repo' do
        criteria = create_criteria('foo')
        criteria.exec :my_method
        expect(criteria.exec).to eq :my_method
      end

      it 'determines that the exec has been assigned' do
        criteria = create_criteria('foo')
        criteria.exec :my_method
        expect(criteria.exec?).to be true
      end
    end

    context '#pager' do
      it 'assigns a pager to the criteria' do
        criteria = create_criteria('foo')
        pager    = create_pager
        criteria.pager(pager)
        expect(criteria.pager).to eq pager
      end

      it 'returns an instance of the criteria to be chained' do
        criteria = create_criteria('foo')
        pager    = create_pager
        expect(criteria.pager(pager)).to eq criteria
      end

      it 'can initialize with a pager' do
        pager    = create_pager
        criteria = create_criteria('foo', pager: pager)
        expect(criteria.pager).to eq pager
      end
    end

    def create_criteria(name, opts = {})
      Criteria.new(name, opts)
    end
  end
end
