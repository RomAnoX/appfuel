module Appfuel::Domain
  RSpec.describe Entity do
    before(:each) do
      setup(app_name: 'foo')
    end

    it 'mixes in Dsl' do
      expect(Entity.ancestors).to include Dsl
    end

    it 'disables value object' do
      expect(Entity.value_object?).to be false
    end

    context '#initialize' do
      it 'creates the entity with no explicitly defined setters' do
        entity = create_domain("Foo::Bar::Baz")
        entity.attribute :foo, 'strict.string', min_size: 4

        instance = entity.new(foo: 'abcde')
        expect(instance.foo).to eq 'abcde'
      end

      it 'build dynamic getter for attribute' do
        entity = create_domain("Foo::Global::Domains::Bob")
        entity.attribute :foo, 'strict.string', min_size: 4, allow_nil: true
        instance = entity.new
        expect(instance.respond_to?(:foo)).to be true
      end

      it 'builds a dynamic setter for attribute' do
        entity = create_domain("Foo::Bar::Fiz")
        entity.attribute :foo, 'strict.string', min_size: 4, allow_nil: true
        instance = entity.new
        expect(instance.respond_to?(:foo=)).to be true
      end

      it 'assigns default value when none is given' do
        entity = create_domain("Foo::Hi::Low")
        entity.attribute :foo, 'strict.string', min_size: 4, default: 'abcd'
        instance = entity.new
        expect(instance.foo).to eq 'abcd'
      end

      it 'assigns Types::Undefined when no value is given' do
        entity = create_domain("Foo::Fiz::Biz")
        entity.attribute :foo, 'strict.string', min_size: 4
        instance = entity.new
        expect(instance.foo).to eq Types::Undefined
      end
    end

    context '#has?' do
      it 'return true when value set' do
        entity = create_domain
        entity.attribute :foo, 'strict.string', min_size: 3
        instance = entity.new(foo: 'bar')
        expect(instance.has?(:foo)).to be true
      end

      it 'return false when value not set' do
        entity = create_domain
        entity.attribute :foo, 'strict.string', min_size: 3
        instance = entity.new
        expect(instance.has?(:foo)).to be false
      end
    end

    def setup(app_name:, data: {})
      container = build_container(data)
      Appfuel.framework_container.register(:default_app_name, app_name)
      Appfuel.framework_container.register(app_name, container)
    end

    def create_domain(class_name = "Foo::Bar::Baz")
      allow(Entity).to receive(:to_s) { class_name }
      Entity
    end
  end
end
