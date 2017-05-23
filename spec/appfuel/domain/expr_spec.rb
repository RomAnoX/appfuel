module Appfuel::Domain
  RSpec.describe Expr do
    context '#initialize' do
      it 'assigns the domain attr when it is an array' do
        expr = create_expr(["foo","bar"], '=', "some-value")
        expect(expr.attr_list).to eq(["foo", "bar"])
      end

      it 'assigns the domain attr when its a string' do
        expr = create_expr("foo.bar", '=', "some-value")
        expect(expr.attr_list).to eq(["foo", "bar"])
      end

      it 'fails when entity is empty' do
        msg = 'attr_list can not be empty'
        expect {
          create_expr([], "=","bar")
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when op is empty' do
        msg = 'op can not be empty'
        expect {
          create_expr(["foo"], "","bar")
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when domain_attr is not a string or array' do
        msg = "Domain attribute must be a string in the form of " +
              "(foo.bar.id) or an array ['foo', 'bar', 'id']"
        expect {
          create_expr(123, "=","bar")
        }.to raise_error(msg)
      end
    end

    context '#conjunction' do
      it 'always returns false' do
        expr = create_expr(["foo"], "=", "bar")
        expect(expr.conjunction?).to be(false)
      end
    end

    context '#global' do
      it 'returns true with qualified global domain' do
        expr = create_expr(["global","foo", "bar"], "=", "blah")
        expect(expr.global?).to be(true)
      end

      it 'returns false with feature  domain attr' do
        expr = create_expr(["features","foo", "bar", "id"], "=", "blah")
        expect(expr.global?).to be(false)
      end

      it 'returns false for non qualified domains' do
        expr = create_expr(["id"], "=", "blah")
        expect(expr.global?).to be(false)
      end
    end

    context '#qualified?' do
      it 'returns false for relative attributes' do
        expr = create_expr(["id"], "=", "blah")
        expect(expr.qualified?).to be(false)
      end

      it 'returns true for qualified attributes' do
        expr = create_expr(["features","foo", "bar", "id"], "=", "blah")
        expect(expr.qualified?).to be(true)
      end
    end

    context '#qualify_feature' do
      it 'qualifies a relative attribute' do
        expr = create_expr(["id"], "=", "blah")
        expr.qualify_feature('foo', 'bar')
        expect(expr.attr_list).to eq(['features', 'foo', 'bar', 'id'])
      end

      it 'fails when the attribute is already qualified' do
        expr = create_expr(["features","boo", "bar", "id"], "=", "blah")
        msg = "this expr is already qualified"
        expect {
          expr.qualify_feature('foo', 'bar')
        }.to raise_error(msg)
      end
    end

    context '#qualify_gloabl' do
      it 'qualifies a relative attribute' do
        expr = create_expr(["id"], "=", "blah")
        expr.qualify_global('bar')
        expect(expr.attr_list).to eq(['global', 'bar', 'id'])
      end

      it 'fails when the attribute is already qualified' do
        expr = create_expr(["features","boo", "bar", "id"], "=", "blah")
        msg = "this expr is already qualified"
        expect {
          expr.qualify_global('bar')
        }.to raise_error(msg)
      end
    end

    context 'op' do
      it 'assigns an eq operator' do
        expr = create_expr(["foo", "bar"], "=", "bar")
        expect(expr.op).to eq '='
      end

      it 'assigns an gt operator' do
        expr = create_expr(["foo"], ">",  44)
        expect(expr.op).to eq ">"
      end

    end

    context 'value' do
      it 'assigns the value' do
        expr = create_expr(["foo"], "=", 'xyz')
        expect(expr.value).to eq 'xyz'
      end

      it 'accepts an array when op in "in"' do
        expr = create_expr(["foo"], "in", ['a', 'b', 'c'])
        expect(expr.value).to eq(['a', 'b', 'c'])
      end
    end

    context '#validate_as_fully_qualified' do
      it 'returns true when the domain attr is qualified' do
        expr = create_expr('global.user.id', '=', 5)
        expect(expr.validate_as_fully_qualified).to be(true)
      end

      it 'fails when the domain attr is not qualified' do
        expr = create_expr('id', '=', 5)
        msg  = 'expr (id = 5) is not fully qualified, mapping will not work'
        expect {
          expr.validate_as_fully_qualified
        }.to raise_error(msg)
      end
    end

    context '#to_s' do
      it 'prints the expression as a string' do
        expr = create_expr('id', '=', 5)
        expect(expr.to_s).to eq("id = 5")
      end
    end

    def create_expr(entity, attr, value)
      Expr.new(entity, attr, value)
    end
  end
end
