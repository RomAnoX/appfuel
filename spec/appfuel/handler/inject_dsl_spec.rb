module Appfuel::Handler
  RSpec.describe InjectDsl do

    context '#injections' do
      it 'returns a hash of empty container and domain hashes' do
        dsl = setup_dsl
        expected = {domains: {}, container: {}}
        expect(dsl.injections).to eq(expected)
      end
    end

    context '#inject' do
      it 'adds a domain injection with no alias' do
        dsl = setup_dsl
        dsl.inject :domain, 'global.user'
        result = dsl.injections[:domains]
        expect(result).to eq({'global.user' => nil})
      end

      it 'adds a domain injection with an alias' do
        dsl = setup_dsl
        dsl.inject :domain, 'foo.bar', as: 'baz'
        result = dsl.injections[:domains]
        expect(result).to eq({'foo.bar' => 'baz'})
      end

      it 'adds a feature command with no alias' do
        dsl = setup_dsl('foo')
        dsl.inject :cmd, 'bar'
        result = dsl.injections[:container]
        expect(result).to eq({'features.foo.commands.bar' => nil})
      end

      it 'adds a global feature with an alias' do
        dsl = setup_dsl('foo')
        dsl.inject :cmd, 'global.bar', as: 'baz'
        result = dsl.injections[:container]
        expect(result).to eq({'global.commands.bar' => 'baz'})
      end

      it 'adds a feature repo with an alias' do
        dsl = setup_dsl('foo')
        dsl.inject :repo, 'bar', as: 'repo'
        result = dsl.injections[:container]
        expect(result).to eq({'features.foo.repositories.bar' => 'repo'})
      end

      it 'adds a global repo with no alias' do
        dsl = setup_dsl('foo')
        dsl.inject :repo, 'global.bar'
        result = dsl.injections[:container]
        expect(result).to eq({'global.repositories.bar' => nil})
      end

      it 'adds a feature container item with no alias' do
        dsl = setup_dsl('foo')
        dsl.inject :container, 'baz'
        result = dsl.injections[:container]
        expect(result).to eq({'features.foo.baz' => nil})
      end

      it 'adds a global container item with an alias' do
        dsl = setup_dsl('foo')
        dsl.inject :container, 'global.baz'
        result = dsl.injections[:container]
        expect(result).to eq({'baz' => nil})
      end

      it 'returns nil' do
        dsl = setup_dsl('foo')
        result = dsl.inject(:repo, 'bar', as: 'repo')
        expect(result).to eq(nil)
      end

      it 'fails when the type of injection is invalid' do
        dsl = setup_dsl
        msg = 'inject type must be domain,cmd,repo,container foo given'
        expect {
          dsl.inject :foo, :bar
        }.to raise_error(RuntimeError, msg)
      end
    end

    def setup_dsl(feature_key_name = 'foo')
      obj = Object.new
      obj.extend(InjectDsl)

      obj.define_singleton_method(:container_feature_key) do
        "features.#{feature_key_name}"
      end

      obj
    end
  end
end
