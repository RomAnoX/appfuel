module Appfuel::Domain
  RSpec.describe Expr do
    context 'entity' do
      it 'assigns the domain name' do
        expr = create_expr('foo.bar', '=', "some-value")
        expect(expr.domain_attr).to eq(["foo", "bar"])
      end

      it 'fails when entity is empty' do
        msg = 'domain_attr can not be empty'
        expect {
          create_expr("", "=","bar")
        }.to raise_error(RuntimeError, msg)
      end
    end

    context 'op' do
      it 'assigns an eq operator' do
        expr = create_expr("foo.id", "=", "bar")
        expect(expr.op).to eq '='
      end

      it 'assigns an gt operator' do
        expr = create_expr("foo", ">",  44)
        expect(expr.op).to eq ">"
      end

    end

    context 'value' do
      it 'assigns the value' do
        expr = create_expr("foo", "=", 'xyz')
        expect(expr.value).to eq 'xyz'
      end

      it 'accepts an array when op in "in"' do
        expr = create_expr("foo", "in", ['a', 'b', 'c'])
        expect(expr.value).to eq(['a', 'b', 'c'])
      end
    end

    def create_expr(entity, attr, value)
      Expr.new(entity, attr, value)
    end
  end
end
