module Appfuel::Repository
  RSpec.describe MappingEntry do
    context '#initialize' do
      it 'fails when there is no domain' do
        msg = 'Fully qualified domain name is required'
        expect {
          create_entry({})
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when there is no persistence' do
        msg = 'Storage classes hash is required'
        expect {
          create_entry(domain_name: 'foo')
        }.to raise_error(RuntimeError, msg)
      end


      it 'fails when there is no persistence_attr' do
        msg = 'Storage attribute is required'
        expect {
          create_entry(domain_name: 'foo', storage: {foo: 'bar'})
        }.to raise_error(RuntimeError, msg)
      end

      it 'fails when there is no entity_attr' do
        data = {
          domain_name: 'foo.bar',
          storage: {
            db: 'foo',
            yaml: 'balh'
          },
          storage_attr: 'bar'
        }
        msg = 'Domain attribute is required'
        expect {
          create_entry(data)
        }.to raise_error(RuntimeError, msg)
      end

      it 'assigns the domain_name' do
        entry = create_entry(default_map_data)

        expect(entry.domain_name).to eq(default_map_data[:domain_name])
      end

      it 'assigns the entity_attr' do
        entry = create_entry(default_map_data)
        expect(entry.domain_attr).to eq(default_map_data[:domain_attr])
      end

      it 'assigns the storage classes' do
        entry = create_entry(default_map_data)
        expect(entry.storage).to eq(default_map_data[:storage])
      end

      it 'assigns the storage attribute' do
        entry = create_entry(default_map_data)
        expect(entry.storage_attr).to eq(default_map_data[:storage_attr])
      end

      it 'skip is false by default' do
        entry = create_entry(default_map_data)
        expect(entry.skip?).to be false
      end

      it 'enables skip' do
        entry = create_entry(default_map_data.merge(skip: true))
        expect(entry.skip?).to be true
      end

      it 'assigns the container name' do
        entry = create_entry(default_map_data.merge(container: 'foo'))
        expect(entry.container).to eq('foo')
      end

      it 'assigns a default value of nil for container' do
        entry = create_entry(default_map_data)
        expect(entry.container).to eq(nil)
      end
    end

    def default_map_data
      {
        domain_name: 'foo.bar',
        domain_attr: 'id',
        storage: {
          db: 'DbFooish'
        },
        storage_attr: 'foo_id',
      }
    end

    def create_entry(data)
      MappingEntry.new(data)
    end
  end
end
