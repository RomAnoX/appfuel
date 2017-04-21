module Appfuel::Handler
  RSpec.describe ValidatorDsl do
    context 'validators' do
      it 'returns an empty list by default when params are nil' do
        dsl = setup_dsl
        expect(dsl.validators).to eq([])
      end
    end

    context 'default_validator_name' do
      it 'returns the handler class name as an undercored string' do
        dsl = setup_dsl
        klass = 'Foo::Bar::ActionBar'
        allow(dsl).to receive(:to_s).with(no_args) { klass }
        expect(dsl.default_validator_name).to eq('action_bar')
      end
    end

    context 'load_validator' do
      it 'returns a validator from "features.foo.validators.a"' do
        container = build_container
        validator = 'I am some validator'
        container.namespace('features.foo.validators') do
          register('a', validator)
        end

        allow(Appfuel).to receive(:app_container).with(no_args) { container }
        dsl = setup_dsl('foo')
        key = 'a'
        expect(dsl.load_validator(key)).to eq(validator)
      end

      it 'returns a validator from "global.validators.b"' do
        container = build_container
        validator = 'I am some validator'
        container.namespace('global.validators') do
          register('b', validator)
        end

        allow(Appfuel).to receive(:app_container).with(no_args) { container }
        dsl = setup_dsl('foo')
        key = 'global.b'
        expect(dsl.load_validator(key)).to eq(validator)
      end

      it 'returns a validator pipe form "features.foo.validator-pipes.c' do
        container = build_container
        pipe = 'I am some pipe'
        container.namespace('features.foo.validator-pipes') do
          register('c', pipe)
        end

        allow(Appfuel).to receive(:app_container).with(no_args) { container }
        dsl = setup_dsl('foo')

        key = 'pipe.c'
        expect(dsl.load_validator(key)).to eq(pipe)
      end

      it 'returns pipe from "globals.validator-pipes.d"' do
        container = build_container
        pipe = 'I am some pipe'
        container.namespace('global.validator-pipes') do
          register('d', pipe)
        end

        allow(Appfuel).to receive(:app_container).with(no_args) { container }
        dsl = setup_dsl('foo')

        key = 'global-pipe.d'
        expect(dsl.load_validator(key)).to eq(pipe)
      end

      it 'fails when a validator can not be found' do
        container = build_container
        allow(Appfuel).to receive(:app_container).with(no_args) { container }

        key = 'd'
        dsl = setup_dsl('foo')
        msg = 'Could not locate validator with (features.foo.validators.d)'
        expect {
          dsl.load_validator(key)
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when key is nil' do
        dsl = setup_dsl('foo')
        msg = 'validator must have a key'
        expect {
          dsl.load_validator(nil)
        }.to raise_error(RuntimeError, msg)
      end
    end

    context 'validator' do
      it 'loads a validator when only a key is given' do
        dsl = setup_dsl
        expect(dsl).to receive(:load_validator).with('foo', {})
        dsl.validator('foo')
      end

      it 'delegates building to Appfuel::Validation when block is given' do
        dsl = setup_dsl
        expect(Appfuel::Validation).to receive(:build_validator).with('foo', {})
        dsl.validator('foo'){}
      end

      it 'adds the validator to the validator list' do
        dsl = setup_dsl
        validator = 'some validator'
        allow(dsl).to receive(:load_validator).with('foo', {}) { validator }

        dsl.validator('foo')
        expect(dsl.validators.first).to eq(validator)
      end

      it 'adds a validator to the list when a block is given' do
        dsl = setup_dsl
        validator = 'some validator'
        expect(Appfuel::Validation).to(
          receive(:build_validator).with('foo', {})
        ) { validator }
        dsl.validator('foo'){}
        expect(dsl.validators.first).to eq(validator)
      end

      it 'returns nil' do
        dsl = setup_dsl
        validator = 'some validator'
        allow(dsl).to receive(:load_validator).with('foo', {}) { validator }

        expect(dsl.validator('foo')).to eq(nil)
      end
    end

    context 'validators' do
      it 'loads multiple validators' do
        container = build_container
        validator_a = 'I am a'
        validator_b = 'I am b'
        container.namespace('features.foo.validators') do
          register('b', validator_b)
          register('a', validator_a)
        end

        allow(Appfuel).to receive(:app_container).with(no_args) { container }
        dsl = setup_dsl('foo')
        dsl.validators('a', 'b')
        expect(dsl.validators[0]).to eq(validator_a)
        expect(dsl.validators[1]).to eq(validator_b)
      end
    end

    context 'validators?' do
      it 'returns false when there are no validators' do
        dsl = setup_dsl
        expect(dsl.validators?).to be false
      end

      it 'returns true when validators exist' do
        dsl = setup_dsl
        validator = 'some validator'
        allow(dsl).to receive(:load_validator).with('foo', {}) { validator }
        dsl.validator('foo')
        expect(dsl.validators?).to be true
      end
    end

    context 'skip_validation?' do
      it 'returns false by default' do
        dsl = setup_dsl
        expect(dsl.skip_validation?).to be false
      end

      it 'returns true when toggled ' do
        dsl = setup_dsl
        dsl.skip_validation!
        expect(dsl.skip_validation?).to be true
      end
    end

    def setup_dsl(feature_key_name = 'foo')
      obj = Object.new
      obj.extend(ValidatorDsl)

      obj.define_singleton_method(:feature_key) do
        "features.#{feature_key_name}"
      end

      obj
    end
  end
end
