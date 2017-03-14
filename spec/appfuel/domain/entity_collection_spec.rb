module Appfuel::Domain
  RSpec.describe EntityCollection do
    context 'interfaces' do
      it 'exposes an enumerable interface' do
        expect(EntityCollection.ancestors).to include(Enumerable)
      end
    end

    context '#initialize' do
      it 'requires the domain name of to populate the collection' do
        domain_name = 'foo.bar'
        domain      = instance_double(Entity)
        allow_domain_type(domain_name, domain)

        collection  = create_collection(domain_name)
        expect(collection.domain_name).to eq domain_name
      end

      it 'fails when domain is not a registered type' do
        domain_name = 'foo.bar'
        msg = 'foo.bar is not a registered type'
        expect {
          create_collection(domain_name)
        }.to raise_error(RuntimeError, msg)
      end

      it 'does not assign an entity load when none is given' do
        domain_name = 'foo.bar'
        domain      = instance_double(Entity)

        allow_domain_type(domain_name, domain)
        collection = create_collection(domain_name)
        expect(collection.entity_loader).to eq nil
      end

      it 'assigns an entity loader when given' do
        domain_name = 'foo.bar'
        domain      = instance_double(Entity)
        loader      = -> {}
        allow_domain_type(domain_name, domain)
        collection = create_collection(domain_name, loader)
        expect(collection.entity_loader).to eq loader
      end

      it 'fails when the loader is not callable' do
        domain_name = 'foo.bar'
        domain      = instance_double(Entity)
        loader      = 'blah'
        allow_domain_type(domain_name, domain)

        msg = 'Entity loader must implement call'

        expect {
          create_collection(domain_name, loader)
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#entity_loader=' do
      it 'assigns an entity loader' do
        domain_name = 'foo.bar'
        domain      = instance_double(Entity)
        loader      = -> {}
        allow_domain_type(domain_name, domain)

        collection = create_collection(domain_name)
        collection.entity_loader = loader
        expect(collection.entity_loader).to eq loader
      end

      it 'fails when entity loader does not implement call' do
        domain_name = 'foo.bar'
        domain      = instance_double(Entity)
        loader      = 'blah'
        allow_domain_type(domain_name, domain)

        collection = create_collection(domain_name)
        msg = 'Entity loader must implement call'

        expect {
          collection.entity_loader = loader
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#entity_loader?' do
      it 'returns false when entity_loader has not been assigned' do
        domain_name = 'foo.bar'
        domain      = instance_double(Entity)
        allow_domain_type(domain_name, domain)

        collection = create_collection(domain_name)
        expect(collection.entity_loader?).to be false
      end

      it 'returns true when entity_loader has been assigned' do
        domain_name = 'foo.bar'
        domain      = instance_double(Entity)
        loader      = -> {}
        allow_domain_type(domain_name, domain)

        collection = create_collection(domain_name)
        collection.entity_loader = loader
        expect(collection.entity_loader?).to be true
      end
    end

    context 'Enumerable' do
      context '#each' do
        it 'yields each domain from the loader' do
          domain_name = 'foo.bar'
          domain      = instance_double(Entity)
          list        = {
            total_pages: 10,
            current_page: 3,
            total_count: 44,
            page_size: 2,
            items: [ 'foo', 'bar', 'baz' ],
          }
          loader      = -> { list }
          allow_domain_type(domain_name, domain)
          collection = create_collection(domain_name, loader)
          expect {|block|
            collection.each(&block)
          }.to yield_successive_args('foo','bar','baz')
        end
      end

      context '#to_h' do
        it 'converts the entity to an array of hashes' do
          domain_name = 'foo.bar'
          domain      = instance_double(Entity)

          entity1 = Object.new
          def entity1.to_h
            {attr_1: 'entity1:value1', attr_2: 'entity1:value2'}
          end

          entity2 = Object.new
          def entity2.to_h
            {attr_1: 'entity2:value1', attr_2: 'entity2:value2'}
          end

          list = {
            total_pages: 2,
            current_page: 1,
            total_count: 2,
            page_size: 2,
            items: [ entity1, entity2 ],
          }

          expected_list = list.dup
          expected_list[:items] = [entity1.to_h, entity2.to_h]
          loader = -> { list }
          allow_domain_type(domain_name, domain)
          collection = create_collection(domain_name, loader)
          expect(collection.to_h).to eq(expected_list)
        end
      end

      context '#to_json' do
        it 'converts the entity to an array of hashes' do
          domain_name = 'foo.bar'
          domain      = instance_double(Entity)

          entity1 = Object.new
          def entity1.to_h
            {attr_1: 'entity1:value1', attr_2: 'entity1:value2'}
          end

          entity2 = Object.new
          def entity2.to_h
            {attr_1: 'entity2:value1', attr_2: 'entity2:value2'}
          end

          list = {
            total_pages: 2,
            current_page: 1,
            total_count: 2,
            page_size: 2,
            items: [ entity1, entity2 ],
          }
          loader = -> { list }
          allow_domain_type(domain_name, domain)
          collection = create_collection(domain_name, loader)

          expected_list = list.dup
          expected_list[:items] = [entity1.to_h, entity2.to_h]
          expected_list = expected_list.to_json
          expect(collection.to_json).to eq(expected_list)
        end
      end
    end

    def create_collection(domain_name, loader = nil)
      EntityCollection.new(domain_name, loader)
    end
  end
end
