module Appfuel::Config
  RSpec.describe DefinitionDsl do
    it 'is created using a key that identifies the config data' do
      definition = create_definition('foo')
      expect(definition.key).to eq :foo
    end

    context '#file' do
      it 'defaults to empty arary' do
        definition = create_definition('foo')
        expect(definition.file).to eq []
      end

      it 'returns the path when setting' do
        path = '/some/path'
        definition = create_definition('foo')
        definition.file path
        expect(definition.file).to eq [path]
      end
    end

    context '#file?' do
      it 'returns false when no file is set' do
        definition = create_definition('foo')
        expect(definition.file?).to be false
      end

      it 'returns true when file is set' do
        definition = create_definition('foo')
        definition.file 'foo/bar'
        expect(definition.file?).to be true
      end
    end

    context '#defaults' do
      it 'returns an empty hash' do
        definition = create_definition('foo')
        expect(definition.defaults).to eq({})
      end

      it 'returns a defaults hash when set' do
        settings = {bar: 'baz'}
        definition = create_definition('foo')
        definition.defaults(settings)
        expect(definition.defaults).to eq settings
      end

      it 'throws an error when settings are not a hash' do
        definition = create_definition('foo')
        expect {
          definition.defaults 'blah'
        }.to raise_error(ArgumentError, 'defaults must be a hash')
      end
    end

    context '#env' do
      it 'returns an empty hash by default' do
        definition = create_definition('foo')
        expect(definition.env).to eq({})
      end

      it 'returns a hash when set' do
        env = {'FOO_BAR' => :bar}
        definition = create_definition('foo')
        definition.env 'FOO_BAR' => :bar
        expect(definition.env).to eq env
      end

      it 'fails when env is not a hash' do
        msg = 'config env settings must be a hash'

        definition = create_definition('foo')
        expect {
          definition.env 'FOO_BAR'
        }.to raise_error(ArgumentError, msg)
      end
    end

    context '#validator' do
      it 'return nil when no validator is set' do
        definition = create_definition('foo')
        expect(definition.validator).to eq nil
      end

      it 'returns the validator that was set' do
        definition = create_definition('foo')

        definition.validator {
          required(:bar).filled(:int?, gt?: 4)
        }

        expect(definition.validator.class).to be < Dry::Validation::Schema
        inputs = {bar: 5}
        result = definition.validator.call(inputs)
        expect(result.success?).to be true
        expect(result.output).to eq inputs
      end
    end

    context '#define' do
      it 'adds a child config detail' do
        root = create_definition('foo')
        root.define 'bar' do
          # dsl usage goes here
        end
        expect(root['bar']).to be_an_instance_of(DefinitionDsl)
      end
    end

    context '#populate' do
      it 'merges settings from the file with defaults' do
        my_defaults = {a: 'a', b: 'b', c: 'c'}
        path        = '/blah.yaml'
        settings    = {'foo' => {a: 'x', c: 'y', f: 'h'}}
        definition  = create_definition('foo')

        definition.file path
        definition.defaults my_defaults

        expected = {
          a: 'x',
          b: 'b',
          c: 'y',
          f: 'h'
        }

        allow(File).to receive(:exists?).with(path) { true }
        allow(YAML).to receive(:load_file).with(path) { settings }
        expect(definition.populate).to eq(expected)
      end

      it 'merges settings from the file with defaults and env' do
        env_data    = {'FOO_A' => 'env_a', 'FOO_C' => 'env_c'}
        my_defaults = {a: 'a', b: 'b', c: 'c'}
        my_env      = {FOO_A: :a, FOO_C: :c}
        path        = '/blah.yaml'
        settings    = {'foo' => {a: 'x', c: 'y', f: 'h'}}
        definition     = create_definition('foo')

        definition.file path
        definition.defaults my_defaults
        definition.env my_env

        expected = {
          a: 'env_a',
          b: 'b',
          c: 'env_c',
          f: 'h'
        }

        allow(File).to receive(:exists?).with(path) { true }
        allow(YAML).to receive(:load_file).with(path) { settings }

        expect(definition.populate(env: env_data)).to eq(expected)
      end

      it 'throws an error if the file can not be found' do
        path  = '/blah.yaml'
        error = "none of :foo config files exist at (/blah.yaml)"
        allow(File).to receive(:exists?).with(path).and_return(false)

        definition = create_definition('foo')
        definition.file path

        expect {
          definition.populate({})
        }.to raise_error(RuntimeError, error)
      end

      it 'throws an error when the load yaml does not return a hash' do

      end

      it 'overrides config file' do
        path      = 'override/file.yaml'
        overrides = { config_file:  path }

        definition = create_definition('foo')
        definition.file '/some/other/file.yaml'
        definition.defaults baz: 'bar', boo: 'baz'

        allow(File).to receive(:exists?).with(path).and_return(true)
        expect(YAML).to receive(:load_file).with(path).and_return({})
        definition.populate(overrides: overrides)
      end

      it 'overrides specific config data' do
        env_data     = {'FOO_A' => 'env_a', 'FOO_C' => 'env_c'}
        my_defaults  = {a: 'a', b: 'b', c: 'c'}
        my_env       = {FOO_A: :a, FOO_C: :c}
        my_overrides = {a: 'override_a', f: 'override_f'}
        path         = '/blah.yaml'
        settings     = {'foo' => {a: 'x', c: 'y', f: 'h'}}
        definition     = create_definition('foo')

        definition.file path
        definition.defaults my_defaults
        definition.env my_env

        expected = {
          a: 'override_a',
          b: 'b',
          c: 'env_c',
          f: 'override_f'
        }

        allow(File).to receive(:exists?).with(path) { true }
        allow(YAML).to receive(:load_file).with(path) { settings }

        populate_params = {
          env: env_data,
          overrides: my_overrides
        }
        expect(definition.populate(populate_params)).to eq(expected)
      end

      it 'loads children definition from file' do
        bar =  {'bar' => {'buz' => 'abc'}}
        bos  = {bos: {'fiz' => '123'}}

        definition = create_definition 'foo'
        definition.define 'bar' do
          file '/tmp/bar.yml'

          define 'bos' do
            file '/tmp/bos.yml'
          end
        end

        allow(File).to receive(:exists?).with('/tmp/bar.yml') { true }
        allow(YAML).to receive(:load_file).with('/tmp/bar.yml') { bar }

        allow(File).to receive(:exists?).with('/tmp/bos.yml') { true }
        allow(YAML).to receive(:load_file).with('/tmp/bos.yml') { bos }

        result = definition.populate(config: {foo: {bam: 'splat'}})
        expected = {
          bam: 'splat',
          bar: {
            buz: 'abc',
            bos: {
              fiz: '123'
            }
          }
        }

        expect(result).to eq(expected)
      end

      it 'fails when child config file does not exist' do
        path = '/non/existant/path.yaml'
        definition = create_definition('foo')
        definition.define 'bar' do
          file path
        end

        allow(File).to receive(:exists?).with(path) { false }

        error = "none of :bar config files exist at (#{path})"
        expect {
          definition.populate(config: {foo: {}})
        }.to raise_error(error)
      end

      it 'fails when yml file does not return a hash' do
        path       = 'foo.yaml'
        settings   = 'this is not right'
        definition = create_definition('foo')
        definition.file(path)


        allow(File).to receive(:exists?).with(path).and_return(true)
        allow(YAML).to receive(:load_file).with(path) { settings }

        error = "[config parse_yaml] config must be a hash"
        expect {
          definition.populate
        }.to raise_error(error)
      end
    end

    context '<<' do
      it 'appends a definition object to its children' do
        definition = create_definition('foo')
        child   = create_definition('bar')
        definition << child
        expect(definition['bar']).to eq child
      end

      it 'appends a list of definition to a detail as children' do
        definition = create_definition('foo')
        child1  = create_definition('bar')
        child2  = create_definition('baz')
        definition << [child1, child2]

        list = [definition['bar'], definition['baz']]
        expect(list).to eq([child1, child2])
      end
    end

    context '[]' do
      it 'finds children from the parent' do
        definition = create_definition('foo')
        child1  = create_definition('bar')
        child2  = create_definition('baz')

        child1 << child2
        definition << child1

        expect(definition['bar baz']).to eq(child2)
      end

      it 'searches the children hierarchy' do
        definition = create_definition('foo')
        child1  = create_definition('bar')
        child2  = create_definition('baz')

        child1 << child2
        definition << child1

        expect(definition.search('bar', 'baz')).to eq(child2)
      end
    end

    def create_definition(key)
      DefinitionDsl.new(key)
    end
  end
end
