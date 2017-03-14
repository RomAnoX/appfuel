module Appfuel::Domain
  RSpec.describe Base do
    context '#initialize' do
      it 'creates the entity with no explicitly defined setters' do
        entity = setup
        entity.attribute :foo, 'strict.string', min_size: 4

        instance = entity.new(foo: 'abcde')
        expect(instance.foo).to eq 'abcde'
      end

      it 'build dynamic getter for attribute' do
        entity = setup
        entity.attribute :foo, 'strict.string', min_size: 4, allow_nil: true
        instance = entity.new
        expect(instance.respond_to?(:foo)).to be true
      end

      it 'builds a dynamic setter for attribute' do
        entity = setup
        entity.attribute :foo, 'strict.string', min_size: 4, allow_nil: true
        instance = entity.new
        expect(instance.respond_to?(:foo=)).to be true
      end

      it 'assigns default value when none is given' do
        entity = setup
        entity.attribute :foo, 'strict.string', min_size: 4, default: 'abcd'
        instance = entity.new
        expect(instance.foo).to eq 'abcd'
      end

      it 'assigns Types::Undefined when no value is given' do
        entity = setup
        entity.attribute :foo, 'strict.string', min_size: 4
        instance = entity.new
        expect(instance.foo).to eq Types::Undefined
      end
    end

    context '#has?' do
      it 'return true when value set' do
        entity = setup
        entity.attribute :foo, 'strict.string', min_size: 3
        instance = entity.new(foo: 'bar')
        expect(instance.has?(:foo)).to be true
      end

      it 'return false when value not set' do
        entity = setup
        entity.attribute :foo, 'strict.string', min_size: 3
        instance = entity.new
        expect(instance.has?(:foo)).to be false
      end
    end

    def setup
      entity = Class.new do
        include Dsl
        include Base
      end

      entity
    end
  end
end
