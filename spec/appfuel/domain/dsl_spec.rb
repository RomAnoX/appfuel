module Appfuel::Domain
  RSpec.describe Dsl do
    context '.attribute' do
      it 'behaves like a normal struct when adding a manual type' do
        entity = setup
        type   = Types::Strict::String
        entity.attribute :foo, type
        expect(entity.schema[:foo]).to eq type
      end

      it 'ignores duplicates when key is the same and type is the same' do
        entity = setup
        type   = Types::Strict::String
        expect {
          entity.attribute :foo, type
          entity.attribute :foo, type
        }.not_to raise_error
      end

      it 'fails as duplicate with key is the same and type is different' do
        entity = setup
        type1  = Types::Strict::String
        type2  = Types::Strict::Int
        msg    = 'Attribute :foo has already been defined as another type'
        expect {
          entity.attribute :foo, type1
          entity.attribute :foo, type2
        }.to raise_error(RuntimeError, msg)
      end

      it 'uses the type string to get the type using Types[]' do
        entity   = setup
        type_str = 'strict.string'
        type     = Types[type_str]

        entity.attribute :foo, type_str
        expect(entity.schema[:foo]).to eq type
      end

      it 'uses type string and optional key to create correct type' do
        entity   = setup
        type_str = 'strict.string'
        type     = Types[type_str].optional

        entity.attribute :foo, type_str, optional: true
        expect(entity.schema[:foo]).to eq type
      end

      it 'uses default with type string' do
        entity   = setup
        type_str = 'strict.string'
        type     = Types[type_str].default('abc')

        entity.attribute :foo, type_str, default: 'abc'
        expect(entity.schema[:foo]).to eq type
      end

      it 'uses default and optional with type string' do
        entity   = setup
        type_str = 'strict.string'
        type     = Types[type_str].default('abc').optional

        entity.attribute :foo, type_str, default: 'abc', optional: true
        expect(entity.schema[:foo]).to eq type
      end

      it 'uses allow nil to sum the given type with nil' do
        entity   = setup
        type_str = 'strict.string'
        type     = Types[type_str] | Types['strict.nil']

        entity.attribute :foo, type_str, allow_nil: true
        expect(entity.schema[:foo]).to eq type
      end

      it 'uses type string to make an array type' do
        entity   = setup
        type_str = 'strict.array'
        type     = Types[type_str].member(Types['strict.string'])

        entity.attribute :foo, type_str, member: 'strict.string'
        expect(entity.schema[:foo]).to eq type
      end

      it 'uses type string to make a hash' do
        entity   = setup
        type_str = 'strict.hash'
        type     = Types[type_str].schema(bar: Types['strict.string'])

        entity.attribute :foo, type_str,
          constructor: :schema, hash: {bar: 'strict.string'}

        expect(entity.schema[:foo]).to eq type
      end

      it 'uses constaints as anything thats not :default, :optional, :allow_nil, :member' do
        entity   = setup
        type_str = 'strict.string'
        type     = Types[type_str].constrained(gt: 3)

        entity.attribute :foo, type_str, gt: 3
        expect(entity.schema[:foo]).to eq type
      end
    end

    context 'attributes of base definition types' do
      definition = Dry::Types::Definition
      {
        "string"    => definition,
        "int"       => definition,
        "symbol"    => definition,
        "class"     => definition,
        "true"      => definition,
        "false"     => definition,
        "bool"      => Dry::Types::Sum,
        "date"      => definition,
        "date_time" => definition,
        "time"      => definition,
        "array"     => Dry::Types::Array,
        "hash"      => Dry::Types::Hash
      }.each do |type_name, klass|
        it "creates a type base definition for #{type_name}" do
          entity = setup
          entity.attribute :foo, type_name
          type = entity.schema[:foo]
          expect(type).to be_an_instance_of(klass)
        end
      end

      definition = Dry::Types::Constrained
      {
        "strict.string"    => definition,
        "strict.int"       => definition,
        "strict.symbol"    => definition,
        "strict.class"     => definition,
        "strict.true"      => definition,
        "strict.false"     => definition,
        "strict.bool"      => Dry::Types::Sum::Constrained,
        "strict.date"      => definition,
        "strict.date_time" => definition,
        "strict.time"      => definition,
        "strict.array"     => definition,
        "strict.hash"      => definition
      }.each do |type_name, klass|
        it "creates a type base definition for #{type_name}" do
          entity = setup
          entity.attribute :foo, type_name
          type = entity.schema[:foo]
          expect(type).to be_an_instance_of(klass)
        end
      end

      definition = Dry::Types::Constructor
      [
        "coercible.string",
        "coercible.int",
        "coercible.float",
        "coercible.decimal",
        "coercible.array",
        "coercible.hash",
      ].each do |type_name|
        it "creates a type base definition for #{type_name}" do
          entity = setup
          entity.attribute :foo, type_name
          type = entity.schema[:foo]
          expect(type).to be_an_instance_of(Dry::Types::Constructor)
        end
      end
    end


    context '.value_object' do
      it 'is disabled by default' do
        entity = setup
        expect(entity.value_object?).to be false
      end

      it 'returns true when enbabled' do
        entity = setup
        entity.enable_value_object
        expect(entity.value_object?).to be true
      end

      it 'returns false when disabled' do
        entity = setup
        entity.enable_value_object
        entity.disable_value_object
        expect(entity.value_object?).to be false
      end
    end

    def setup
      entity = Class.new do
        extend Dsl
      end

      entity
    end
  end
end
