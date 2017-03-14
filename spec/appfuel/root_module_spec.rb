module Appfuel
  RSpec.describe RootModule do

    it 'finds the first module in class chain' do
      klass = setup
      root  = class_double(Module)
      name  = 'Foo::Bar::Baz'

      allow(klass).to receive(:to_s).with(no_args) { name }
      allow_const_defined_as_true(Kernel, 'Foo')
      allow_const_get(Kernel, 'Foo', root)

      expect(klass.root_module).to eq(root)
    end

    it 'fails when the top module is not defined' do
      klass   = setup
      name    = 'Foo::Bar::Baz'

      allow(klass).to receive(:to_s).with(no_args) { name }
      allow_const_defined_as_false(Kernel, 'Foo')
      msg = 'Root module is not defined (Foo)'
      expect {
        klass.root_module
      }.to raise_error(RuntimeError, msg)
    end

    it 'fails when assigning a top module that is not a module' do
      klass = setup
      invalid_module = 'Foo'

      msg = 'Root module must be a module'
      expect {
        klass.root_module = invalid_module
      }.to raise_error(RuntimeError, msg)
    end

    it 'assigns a top module manually' do
      klass = setup
      valid_module = class_double(Module)
      allow(valid_module).to receive(:is_a?).with(Module) { true }
      klass.root_module = valid_module

      expect(klass.root_module).to eq(valid_module)
    end

    def setup
      klass = Object.new
      klass.extend(RootModule)
    end

  end
end
