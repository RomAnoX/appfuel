module Appfuel
  RSpec.describe ContainerDependency do
    it 'has do db dependencies by default' do
      expect(setup.container_dependencies).to eq({})
    end

    context '#container' do
      it 'declared a dependency using container with no alias' do
        obj = setup
        obj.container :foo
        expect(obj.container_dependencies).to eq({foo: nil})
      end

      it 'declare a dependency with an alias' do
        obj = setup
        obj.container :foo, as: :bar
        expect(obj.container_dependencies).to eq({foo: :bar})
      end

      context 'resolve_container' do
        it 'fails when top module is not a Module' do
          root = 'I am no a module'
          obj  = setup(root)
          msg  = 'top module must be a Module'
          expect {
            obj.resolve_container(:foo)
          }.to raise_error(RuntimeError, msg)
        end

        it 'fails when dependency is not in container' do
          container = create_container
          top_mod   = double('some module')

          allow(top_mod).to receive(:is_a?).with(Module).and_return(true)
          allow(top_mod).to receive(:container)
            .with(no_args).and_return(container)

          result = create_container

          obj = setup(top_mod)
          obj.container :foo
          msg = 'Nothing registered with the key :foo'
          expect {
          obj.resolve_container(result)
          }.to raise_error(Dry::Container::Error, msg)
        end

        it 'adds dependencies in app container (top_module) to result' do
          container = create_container
          top_mod   = double('some module')

          container.register(:foo, 'foo')
          container.register(:bar, 'bar')

          allow(top_mod).to receive(:is_a?).with(Module).and_return(true)
          allow(top_mod).to receive(:container)
            .with(no_args).and_return(container)

          result = create_container

          obj = setup(top_mod)
          obj.container :foo
          obj.container :bar, as: :baz
          obj.resolve_container(result)

          expect(result[:foo]).to eq 'foo'
          expect(result[:baz]).to eq 'bar'
        end
      end

    end

    def setup(root_module = 'some mock')
      obj = Class.new do
        extend ContainerDependency
      end

      obj.class_eval do
        define_singleton_method :root_module do
          root_module
        end
      end

      obj
    end

    def create_container
      Dry::Container.new
    end
  end
end
