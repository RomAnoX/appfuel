module Appfuel::Domain
  RSpec.describe Expr do

    context 'entity' do
      it 'assigns the domain name' do
        expr = create_expr('foo.bar', 'id', eq: "bar")
        expect(expr.domain_name).to eq "foo.bar"
      end

      it 'fails when entity is empty' do
        msg = 'domain name can not be empty'
        expect {
          create_expr("", "id", eq: "bar")
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when entity is nil' do
        msg = 'domain name must be a string or implement method :domain_name'
        expect {
          create_expr(nil, "id", eq: "bar")
        }.to raise_error(RuntimeError, msg)
      end
    end

    context 'domain_attr' do
      it 'assigns the attribute as a string when a symbol is given' do
        expr = create_expr('foo.bar', :foo, eq: "bar")
        expect(expr.domain_attr).to eq "foo"
      end

      it 'assigns the domain attribute as a string when a symbol is given' do
        expr = create_expr('foo.bar', "foo_id", eq: "bar")
        expect(expr.domain_attr).to eq "foo_id"
      end

      it 'fails when domain_attr is an empty string' do
        msg = 'domain attribute can not be empty'
        expect {
          create_expr('foo.bar', "", eq: "bar")
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when domain_attr is nil' do
        msg = 'domain attribute can not be empty'
        expect {
          create_expr('foo.bar', nil, eq: "bar")
        }.to raise_error(RuntimeError, msg)
      end
    end

    context 'op' do
      it 'assigns an eq operator' do
        expr = create_expr("foo", "name", eq: "bar")
        expect(expr.op).to eq :eq
      end

      it 'assigns an eq op when operator is a string' do
        expr = create_expr("foo", "name", 'eq'=>"bar")
        expect(expr.op).to eq :eq
      end

      it 'assigns an gt operator' do
        expr = create_expr("foo", "id", gt: 44)
        expect(expr.op).to eq :gt
      end

      it 'assigns an gteq operator' do
        expr = create_expr("foo", "id", gteq: 44)
        expect(expr.op).to eq :gteq
      end


      it 'assigns an lt operator' do
        expr = create_expr("foo", "id", lt: 44)
        expect(expr.op).to eq :lt
      end

      it 'assigns an lteq operator' do
        expr = create_expr("foo", "id", lteq: 44)
        expect(expr.op).to eq :lteq
      end

      it 'assigns an in operator' do
        expr = create_expr("foo", "id", in: ['x', 'y', 'z'])
        expect(expr.op).to eq :in
      end

      it 'assigns an in operator as a string' do
        expr = create_expr("foo", "id", 'in' => ['x', 'y', 'z'])
        expect(expr.op).to eq :in
      end

      it 'assigns a like operator' do
        expr = create_expr("foo", "name", like: 'xyz')
        expect(expr.op).to eq :like
      end

      it 'assigns a like operator as a string' do
        expr = create_expr("foo", "name", 'like' => 'xyz')
        expect(expr.op).to eq :like
      end

      it 'fails when an unrecognised op is used' do
        msg = 'op has to be one of [eq,gt,gteq,lt,lteq,in,like,ilike,between]'
        expect {
          create_expr("foo", "name", 'boo' => 'xyz')
        }.to raise_error(RuntimeError, msg)
      end

      it 'knows op is not_eq when using :not_eq' do
        expr = create_expr("foo", "name", not_eq: "bar")
        expect(expr.op).to eq :not_eq
      end

      it 'negates the expr when using :not_eq' do
        expr = create_expr("foo", "name", not_eq: "bar")
        expect(expr).to be_negated
      end

      it 'knows op is :not_in when using :not_in' do
        expr = create_expr("foo", "name", not_in: ["bar"])
        expect(expr.op).to eq :not_in
      end

      it 'negates the expr when using :not_in' do
        expr = create_expr("foo", "name", not_in: ["bar"])
        expect(expr).to be_negated
      end

      it 'knows op is :not_like in when using :not_like' do
        expr = create_expr("foo", "name", not_like: "bar")
        expect(expr.op).to eq :not_like
      end

      it 'negates the expr when using :not_like' do
        expr = create_expr("foo", "name", not_like: "bar")
        expect(expr).to be_negated
      end

      it 'knows op is :between in when using :between' do
        expr = create_expr("foo", "id", between: [1, 5])
        expect(expr.op).to eq :between
      end

      it 'knows op is :not_between in when using :not_between' do
        expr = create_expr("foo", "id", not_between: [1, 5])
        expect(expr.op).to eq :not_between
      end

      it 'negates the expr when using :not_between' do
        expr = create_expr("foo", "name", not_between: "bar")
        expect(expr).to be_negated
      end
    end

    context '#negated?' do
      it 'is false by default' do
        expr = create_expr("foo", "name", eq: 'xyz')
        expect(expr.negated?).to be false
      end
    end

    context 'value' do
      it 'assigns the value' do
        expr = create_expr("foo", "name", eq: 'xyz')
        expect(expr.value).to eq 'xyz'
      end

      it 'accepts an array when op in "in"' do
        expr = create_expr("foo", "name", in: ['a', 'b', 'c'])
        expect(expr.value).to eq(['a', 'b', 'c'])
      end

      it 'fails when value of in operator is not an array' do
        msg = ':in operator must have an array as a value'
        expect {
          create_expr("foo", "name", in: 'abc')
        }.to raise_error(RuntimeError, msg)
      end
    end

    def create_expr(entity, attr, value)
      Expr.new(entity, attr, value)
    end
  end
end
