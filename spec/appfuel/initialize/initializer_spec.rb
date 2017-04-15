module Appfuel::Initialize
  RSpec.describe Initializer do
    context '#initialize' do
      it 'assigns the initializer name as string' do
        init = create_initializer(:foo) {}
        expect(init.name).to eq 'foo'
      end

      it 'adds a single env to the env list' do
        init = create_initializer(:foo, :dev) {}
        expect(init.envs).to eq(['dev'])
      end

      it 'adds a list of env' do
        init = create_initializer(:foo, [:dev, :qa]) {}
        expect(init.envs).to eq(['dev', 'qa'])
      end

      it 'downcases all environment codes' do
        init = create_initializer(:foo, :PROD) {}
        expect(init.envs).to eq(['prod'])
      end

      it 'defaults to an empty list of envs' do
        init = create_initializer(:foo) {}
        expect(init.envs).to eq([])
      end

      it 'fails when envs are not a hash, string or symbol' do
        msg = 'environments must be a string, symbol or array'
        expect {
          create_initializer(:foo, 1234) {}
        }.to raise_error(ArgumentError, msg)
      end

      it 'fails when no block is given' do
        msg = 'initializer requires a block'
        expect {
          create_initializer(:foo)
        }.to raise_error(ArgumentError, msg)
      end

      it 'assigns the code as a proc' do
        init = create_initializer(:foo) {}
        expect(init.code).to be_an_instance_of(Proc)
      end
    end

    def create_initializer(name, env = [], &blk)
      Initializer.new(name, env, &blk)
    end
  end
end
