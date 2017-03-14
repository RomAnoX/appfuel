module Appfuel::Domain
  RSpec.describe EntityNotFound do

    describe 'initialize' do
      it 'delegates domain_name' do
        _entity_class, instance = setup_entity('Foo', 'foo')
        expect(instance).to receive(:domain_name).with(no_args) { 'some name' }

        not_found = EntityNotFound.new(entity_name: 'foo')
        expect(not_found.domain_name).to eq 'some name'
        tear_down('Foo')
      end

      it 'delegates attr_typed!' do
        _entity_class, instance = setup_entity('Foo', 'foo')

        expect(instance).to receive(:attr_typed!).with(:id, 99) { 99 }

        not_found = EntityNotFound.new(entity_name: 'foo')
        expect(not_found.attr_typed!(:id, 99)).to eq 99

        tear_down('Foo')
      end

      it 'delegates data_typed!' do
        _entity_class, instance = setup_entity('Foo', 'foo')

        expect(instance).to receive(:data_typed!).with(:id, 99) { 99 }

        not_found = EntityNotFound.new(entity_name: 'foo')
        expect(not_found.data_typed!(:id, 99)).to eq 99

        tear_down('Foo')
      end


      it 'delegates data_typed' do
        _entity_class, instance = setup_entity('Foo', 'foo')

        expect(instance).to receive(:data_type).with(:id) { 'some result' }

        not_found = EntityNotFound.new(entity_name: 'foo')
        expect(not_found.data_type(:id)).to eq 'some result'

        tear_down('Foo')
      end


      it 'delegates validate_type!' do
        _entity_class, instance = setup_entity('Foo', 'foo')

        expect(instance).to receive(:validate_type!)
          .with(:type, :str, {}) { 'some result' }

        not_found = EntityNotFound.new(entity_name: 'foo')
        expect(not_found.validate_type!(:type, :str)).to eq 'some result'

        tear_down('Foo')
      end

      it 'delegates basename' do
        _entity_class, instance = setup_entity('Foo', 'foo')

        expect(instance).to receive(:basename).with(no_args) {'results'}

        not_found = EntityNotFound.new(entity_name: 'foo')
        expect(not_found.basename).to eq 'results'

        tear_down('Foo')
      end

      it 'has? will return false' do
        _entity_class, _instance = setup_entity('Foo', 'foo')

        not_found = EntityNotFound.new(entity_name: 'foo')
        expect(not_found.has?(:id)).to be false

        tear_down('Foo')
      end

      it 'delegates to_hash' do
        _entity_class, instance = setup_entity('Foo', 'foo')

        expect(instance).to receive(:to_h).with(no_args) {'results'}

        not_found = EntityNotFound.new(entity_name: 'foo')
        expect(not_found.to_hash).to eq 'results'

        tear_down('Foo')
      end
    end

    def setup_entity(class_name, entity_name)
      entity = Class.new(Entity)

      Object.const_set(class_name, entity)
      allow_domain_type(entity_name, entity)

      instance = instance_double(entity)
      allow(entity).to receive(:new).with({}) { instance }
      [entity, instance]
    end

    def tear_down(entity_class)
      Object.send(:remove_const, entity_class)
    end
  end
end
