module Appfuel
  RSpec.describe EntityExpr do

    context 'entity' do
      it 'assigns the entity name' do
        expr = create_expr('foo.bar', 'id', eq: "bar")
        expect(expr.entity).to eq "foo.bar"
      end

      it 'fails when entity is empty' do
        msg = 'entity name can not be empty'
        expect {
          create_expr("", "id", eq: "bar")
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when entity is nil' do
        msg = 'entity name can not be empty'
        expect {
          create_expr(nil, "id", eq: "bar")
        }.to raise_error(RuntimeError, msg)
      end
    end

    context 'attr' do
      it 'assigns the attribute as a string when a symbol is given' do
        expr = create_expr('foo.bar', :foo, eq: "bar")
        expect(expr.attr).to eq "foo"
      end

      it 'assigns the attribute as a string when a symbol is given' do
        expr = create_expr('foo.bar', "foo_id", eq: "bar")
        expect(expr.attr).to eq "foo_id"
      end

      it 'fails when attr is an empty string' do
        msg = 'attribute can not be empty'
        expect {
          create_expr('foo.bar', "", eq: "bar")
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when attr is nil' do
        msg = 'attribute can not be empty'
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

      it 'assigns a range operator as a symbol' do
        range = Time.now .. Time.now + 1
        expr  = create_expr("foo", "created_at", 'range' => range)
        expect(expr.op).to eq :range
      end

      it 'fails when an unrecognised op is used' do
        msg = 'op has to be one of [eq,gt,gteq,lt,lteq,in,like,range]'
        expect {
          create_expr("foo", "name", 'boo' => 'xyz')
        }.to raise_error(RuntimeError, msg)
      end

      it 'knows op is eq when using :not_eq' do
        expr = create_expr("foo", "name", not_eq: "bar")
        expect(expr.op).to eq :eq
      end

      it 'negates the expr when using :not_eq' do
        expr = create_expr("foo", "name", not_eq: "bar")
        expect(expr).to be_negated
      end

      it 'knows op is :in when using :not_in' do
        expr = create_expr("foo", "name", not_in: ["bar"])
        expect(expr.op).to eq :in
      end

      it 'negates the expr when using :not_in' do
        expr = create_expr("foo", "name", not_in: ["bar"])
        expect(expr).to be_negated
      end

      it 'knows op is :like in when using :not_like' do
        expr = create_expr("foo", "name", not_like: "bar")
        expect(expr.op).to eq :like
      end

      it 'negates the expr when using :not_like' do
        expr = create_expr("foo", "name", not_like: "bar")
        expect(expr).to be_negated
      end

      it 'knows op is :range in when using :not_range' do
        expr = create_expr("foo", "name", not_range: (1..3))
        expect(expr.op).to eq :range
      end

      it 'negates the expr when using :not_range' do
        expr = create_expr("foo", "name", not_range: (1..3))
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

      it 'fails when range is not a range' do
        msg = ':range operator must have a range as a value'
        expect {
          create_expr("foo", "name", range: 'abc')
        }.to raise_error(RuntimeError, msg)
      end
    end

    def create_expr(entity, attr, value)
      EntityExpr.new(entity, attr, value)
    end
  end
end
