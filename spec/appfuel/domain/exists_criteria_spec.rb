module Appfuel::Domain
  RSpec.describe BaseCriteria do
    context 'initialize' do
      it 'initializes with no expressions when given no args' do
        criteria = create_criteria('foo.bar')
        expect(criteria.filters?).to be false
      end
    end

    context '#filter' do
      it 'adds the expression for the exists interface' do
        criteria = create_criteria('foo.bar')
        criteria.filter('id = 6')
        expr = criteria.filters
        expect(expr).to be_an_instance_of(Expr)
        expect(expr.value).to eq(6)
      end

      it 'fails if the expression is a conjunction' do
        criteria = create_criteria('foo.bar')
        msg = "Only simple domain expressions are allowed for exists criteria"
        expect {
          criteria.filter('id = 6 and bar = 6 and baz = 7')
        }.to raise_error(msg)
      end

      it 'fails if the expression as already been assigned' do
        criteria = create_criteria('foo.bar')
        criteria.filter('id = 6')
        msg = "A filter expression has already been assigned"
        expect {
          criteria.filter('id = 7')
        }.to raise_error(msg)
      end

      it 'qualifies the expression with an feature and domain' do
        criteria = create_criteria('foo.bar')
        expr = criteria.filter('id = 6').filters
        expect(expr.attr_list).to eq(['features', 'foo', 'bar', 'id'])
      end

      it 'qualifies the expression correctly when global' do
        criteria = create_criteria('global.user')
        expr = criteria.filter('id = 6').filters
        expect(expr.attr_list).to eq(['global', 'user', 'id'])
      end

      it 'does not qualify the expression if it is qualified' do
        criteria = create_criteria('foo.bar')
        msg = "Only allows relative domain attributes"
        expect {
          criteria.filter('features.foo.bar.user.id = 6').filters
        }.to raise_error(msg)
      end

      it 'fails when parser does not implement parse' do
        criteria = create_criteria('foo.bar', expr_parser: 'blah')
        msg = "expression parser must implement to :parse"
        expect {
          criteria.filter('id = 6')
        }.to raise_error(msg)
      end

      it 'fails when transform does not implement apply' do
        criteria = create_criteria('foo.bar', expr_transform: 'blah')
        msg = "expression transform must implement :apply"
        expect {
          criteria.filter('id = 6')
        }.to raise_error(msg)
      end

      it 'fails when it parses incorrectly' do
        criteria = create_criteria('foo.bar')
        msg = "The expression (id 6) failed to parse"
        expect {
          criteria.filter('id 6')
        }.to raise_error(msg)
      end

      it 'fails when parser does not return :domain_expr or :root' do
        parser = double("some parser")
        str    = 'id = 6'
        allow(parser).to receive(:parse).with(str) { {wrong_key: 'foo' } }

        criteria = create_criteria('foo.bar', expr_parser: parser)

        msg = "unable to parse (id = 6) correctly"
        expect {
          criteria.filter(str)
        }.to raise_error(msg)
      end
    end

    context '#clear_filters' do
      it 'resets filters to nil' do
        criteria = create_criteria('foo.bar')
        criteria.filter('id = 6').clear_filters

        expect(criteria.filters).to eq(nil)
      end
    end

    def create_criteria(domain_name, settings = {})
      ExistsCriteria.new(domain_name, settings)
    end
  end
end
