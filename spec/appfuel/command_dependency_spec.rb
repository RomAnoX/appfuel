module Appfuel
  RSpec.describe CommandDependency do
    it 'has do command dependencies by default' do
      expect(setup.command_dependencies).to eq({feature: {}, global: {}})
    end

    context '#command' do
      it 'declared a dependency using command with no alias' do
        obj = setup
        obj.command :foo
        expect(obj.command_dependencies[:feature]).to eq({foo: nil})
      end

      it 'declare a dependency with an alias' do
        obj = setup
        obj.command :foo, as: :bar
        expect(obj.command_dependencies[:feature]).to eq({foo: :bar})
      end

      it 'declares a global dependency with no alias' do
        obj = setup
        obj.command :foo, global: true
        expect(obj.command_dependencies[:global]).to eq({foo: nil})
      end

      it 'declares a global dependency with an alias' do
        obj = setup
        obj.command :foo, as: :bar, global: true
        expect(obj.command_dependencies[:global]).to eq({foo: :bar})
      end

      context 'resolve_feature_command' do
        it 'finds a command that exists locally' do
          feature_mod = class_double(Module)
          command_mod = class_double(Module)

          result  = 'my domain'
          allow(feature_mod).to receive(:const_defined?)
            .with(:Commands).and_return(true)

          allow(feature_mod).to receive(:const_get)
            .with(:Commands).and_return(command_mod)

          allow(command_mod).to receive(:const_defined?)
            .with("Foo").and_return(true)

          allow(command_mod).to receive(:const_get)
            .with("Foo").and_return(result)

          obj = setup('some_mock', feature_mod)

          expect(obj.resolve_feature_command(:foo)).to eq result
        end

        it 'fails when feature module is not a Module' do
          feature_mod = 'I am no a module'
          obj = setup('top mod', feature_mod)
          msg = 'feature module must be a Module'
          expect {
            obj.resolve_feature_command(:foo)
          }.to raise_error(RuntimeError, msg)
        end

        it 'fails when commands module does not exist' do
          feature_mod = class_double(Module)
          allow(feature_mod).to receive(:const_defined?)
            .with(:Commands).and_return(false)


          obj = setup('mock top', feature_mod)
          msg = "Commands not found in #{feature_mod}"
          expect {
            obj.resolve_feature_command(:foo)
          }.to raise_error(RuntimeError, msg)
        end
      end

      context 'resolve_global_command' do
        it 'fails when root module is not a Module' do
          root = 'I am no a module'
          obj     = setup(root, 'feature mod')
          msg     = 'root module must be a Module'
          expect {
            obj.resolve_global_command(:foo)
          }.to raise_error(RuntimeError, msg)
        end

        it 'fails when commands module does not exist in top module' do
          root = class_double(Module)

          allow(root).to receive(:const_defined?).with(:Commands) { false }

          obj = setup(root, 'feature module')
          msg = "Commands not found in #{root}"
          expect {
            obj.resolve_global_command(:foo)
          }.to raise_error(RuntimeError, msg)
        end

        it 'fails when command not found in top module' do
          root = class_double(Module)
          cmd_mod = class_double(Module)

          allow(root).to receive(:const_defined?).with(:Commands) {true}
          allow(root).to receive(:const_get).with(:Commands) {cmd_mod}
          allow(cmd_mod).to receive(:const_defined?).with("Foo") {false}

          obj = setup(root, 'feature mod')
          msg = "command Foo not found in #{root}"
          expect {
            obj.resolve_global_command(:foo)
          }.to raise_error(RuntimeError, msg)
        end

        it 'returns command from top module' do
          root = class_double(Module)
          cmd_mod  = class_double(Module)
          result = 'foo result'
          allow(root).to receive(:const_defined?).with(:Commands) {true}
          allow(root).to receive(:const_get).with(:Commands) {cmd_mod}
          allow(cmd_mod).to receive(:const_defined?).with("Foo") {true}
          allow(cmd_mod).to receive(:const_get).with("Foo") {result}

          obj = setup(root, 'feature mod')
          expect(obj.resolve_global_command(:foo)).to eq result
        end
      end

      context 'resolve_commands' do
        it 'resolves a feature command and a global command' do
          root          = class_double(Module)
          feature_mod      = class_double(Module)
          feature_commands = class_double(Module)
          top_commands     = class_double(Module)
          feature_result   = 'my feature command'
          top_result       = 'my global command'

          allow(feature_mod).to receive(:const_defined?)
            .with(:Commands).and_return(true)

          allow(feature_mod).to receive(:const_get)
            .with(:Commands).and_return(feature_commands)

          allow(feature_commands).to receive(:const_defined?)
            .with("Foo").and_return(true)

          allow(feature_commands).to receive(:const_get)
            .with("Foo").and_return(feature_result)

          allow(feature_commands).to receive(:const_defined?)
            .with("Bar").and_return(false)

          allow(root).to receive(:const_defined?)
            .with(:Commands).and_return(true)

          allow(root).to receive(:const_get)
            .with(:Commands).and_return(top_commands)

          allow(top_commands).to receive(:const_defined?).
            with('Bar').and_return(true)

          allow(top_commands).to receive(:const_get).
            with('Bar').and_return(top_result)

          obj = setup(root, feature_mod)
          obj.command :foo
          obj.command :bar, global: true


          container = create_container
          obj.resolve_commands(container)
          expect(container[:foo]).to eq feature_result
          expect(container[:bar]).to eq top_result
        end
      end
    end

    def setup(root_module = 'mock root', feature_module = 'mock feature')
      obj = Class.new do
        include CommandDependency

      end

      obj.class_eval do
        define_singleton_method :root_module do
          root_module
        end

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
