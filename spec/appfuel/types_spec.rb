module Appfuel
  RSpec.describe Types do
    describe '.register' do
      it 'returns a try container' do
        expect(Types.container).to be_an_instance_of(Dry::Types::Container)
      end

      it 'registers a validation type into the type container' do
        type = 'SomeType'
        key  = 'foo'
        Types.register(key, type)
        expect(Types['foo']).to eq type
      end

      it 'registers the type into Dry::Types container' do
        type = 'SomeOtherType'
        key  = :fiz
        Types.register(key, type)
        expect(Dry::Types.container[:fiz]).to eq type
      end
    end

    describe Types::Db do
      describe '.container' do
        it 'returns a try container' do
          expect(Types::Db.container).to be_an_instance_of(Dry::Container)
        end
      end

      describe '.register' do
        it 'registers an object as a db type' do
          type = double('Some db class')
          Types::Db.register(:foo, type)
          expect(Types::Db[:foo]).to eq type
        end
      end
    end
  end
end
