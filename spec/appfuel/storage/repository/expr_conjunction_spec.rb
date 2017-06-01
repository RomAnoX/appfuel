module Appfuel::Repository
  RSpec.describe ExprConjunction do
    context '#initialize' do
      it 'creates an "and" conjunction"' do
        left   = create_expr('id', '=', 9)
        right  = create_expr('id', '=', 8)
        result = create_conjunction('and', left, right)
        expect(result.op).to eq('and')
        expect(result.left).to eq(left)
        expect(result.right).to eq(right)
      end

      it 'creates an "or" conjunction"' do
        left   = create_expr('id', '=', 9)
        right  = create_expr('id', '=', 8)
        result = create_conjunction('or', left, right)
        expect(result.op).to eq('or')
        expect(result.left).to eq(left)
        expect(result.right).to eq(right)
      end

      it 'fails when operator is not "and" or "or"' do
        left   = create_expr('id', '=', 9)
        right  = create_expr('id', '=', 8)
        msg    = "conjunction operator can only be (and|or)"
        expect {
          create_conjunction('bad', left, right)
        }.to raise_error(msg)
      end
    end

    context '#conjunction?' do
      it 'always returns true' do
        left   = create_expr('id', '=', 9)
        right  = create_expr('id', '=', 8)
        result = create_conjunction('or', left, right)
        expect(result.conjunction?).to be(true)
      end
    end

    context '#qualified?' do
      it 'returns true when both left and right are qualified' do
        left  = instance_double(Expr)
        right = instance_double(Expr)
        allow_qualified(left, true)
        allow_qualified(right, true)
        result = create_conjunction('or', left, right)
        expect(result.qualified?).to be(true)
      end

      it 'returns false when left is not qualified and right is' do
        left  = instance_double(Expr)
        right = instance_double(Expr)
        allow_qualified(left, false)
        allow_qualified(right, true)
        result = create_conjunction('or', left, right)
        expect(result.qualified?).to be(false)
      end

      it 'returns false when left is qualified and right is not' do
        left  = instance_double(Expr)
        right = instance_double(Expr)
        allow_qualified(left, true)
        allow_qualified(right, false)
        result = create_conjunction('or', left, right)
        expect(result.qualified?).to be(false)
      end

      it 'returns false when both left and right are not qualified' do
        left  = instance_double(Expr)
        right = instance_double(Expr)
        allow_qualified(left, false)
        allow_qualified(right, false)
        result = create_conjunction('and', left, right)
        expect(result.qualified?).to be(false)
      end
    end

    context '#qualify_feature' do
      it 'will qualify both left and right' do
        left   = create_expr('id', '=', 9)
        right  = create_expr('id', '=', 8)
        result = create_conjunction('and', left, right)
        result.qualify_feature('foo', 'bar')
        expect(left.qualified?).to be(true)
        expect(right.qualified?).to be(true)
        expect(left.global?).to be(false)
        expect(right.global?).to be(false)
      end
    end

    context '#qualify_global' do
      it 'will qualify both left and right' do
        left   = create_expr('id', '=', 9)
        right  = create_expr('id', '=', 8)
        result = create_conjunction('and', left, right)
        result.qualify_global('bar')
        expect(left.qualified?).to be(true)
        expect(right.qualified?).to be(true)
        expect(left.global?).to be(true)
        expect(right.global?).to be(true)
      end
    end
    def allow_qualified(expr, value)
      allow(expr).to receive(:qualified?).with(no_args) { value }
    end

    def create_expr(str, op, value)
      Expr.new(str, op, value)
    end

    def create_conjunction(type, left, right)
      ExprConjunction.new(type, left, right)
    end
  end
end
