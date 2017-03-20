module Appfuel::Domain
  RSpec.describe DependencyInjectionDsl do
    it 'has do domain dependencies by default' do
      expect(setup.domain_dependencies).to eq({feature: {}, global: {}})
    end

    context '#domain' do
      it 'declared a dependency using domain with no alias' do
        obj = setup
        obj.domain :foo
        expect(obj.domain_dependencies[:feature]).to eq({foo: nil})
      end

      it 'declare a dependency with an alias' do
        obj = setup
        obj.domain :foo, as: :bar
        expect(obj.domain_dependencies[:feature]).to eq({foo: :bar})
      end

      it 'declares a global dependency with no alias' do
        obj = setup
        obj.domain :foo, global: true
        expect(obj.domain_dependencies[:global]).to eq({foo: nil})
      end

      it 'declares a global dependency with an alias' do
        obj = setup
        obj.domain :foo, as: :bar, global: true
        expect(obj.domain_dependencies[:global]).to eq({foo: :bar})
      end
    end

    context 'resolve_domains' do
      it 'resolves a feature domain' do
        feature_mod = class_double(Module)
        domain      = entity_class_double

        allow(feature_mod).to receive(:name).with(no_args) {'Top::FooFeature'}
        allow_type('foo_feature.foo', domain)

        obj = setup(feature_mod)
        obj.domain :foo

        results = obj.resolve_domains
        expect(results[:foo]).to eq domain
      end

      it 'fails when there is no domain in the feature' do
        feature_mod = class_double(Module)
        obj = setup(feature_mod)

        allow(feature_mod).to receive(:name).with(no_args) {'Top::FooFeature'}
        obj.domain :foo

        msg = 'Nothing registered with the key "foo_feature.foo"'
        expect {
          obj.resolve_domains
        }.to raise_error(Dry::Container::Error, msg)
      end

      it 'fails when there is no global domain' do
        obj = setup

        obj.domain :blah, global: true

        msg = 'Nothing registered with the key "blah"'
        expect {
          obj.resolve_domains
        }.to raise_error(Dry::Container::Error, msg)
      end
    end

    def setup(feature_module = 'mock feature')
      obj = Class.new do
        extend DependencyInjectionDsl
      end

      obj.class_eval do
        define_singleton_method :feature_module do
          feature_module
        end
      end

      obj
    end

    def create_container
      Dry::Container.new
    end

  end
end
