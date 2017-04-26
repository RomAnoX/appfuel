module Appfuel::Application
  RSpec.describe ContainerKey do
    context '#parse_list_string' do
      it 'parses a ruby namespace into an array of lower case snakecase' do
        mixin = setup
        namespace = 'Foo::BarBaz::Biz'
        expected  = ['foo', 'bar_baz', 'biz']
        expect(mixin.parse_list_string(namespace, '::')).to eq(expected)
      end

      it 'parses a period delineated list into an array' do
        mixin = setup
        namespace = 'foo.boo_bar.baz'
        expected  = ['foo', 'boo_bar', 'baz']
        expect(mixin.parse_list_string(namespace, '.')).to eq(expected)
      end

      it 'fails when the delineated character in not "." or "::"' do
        mixin = setup
        msg = "split char must be '.' or '::'"
        expect {
          mixin.parse_list_string('Blah:Blah:Blah', '!')
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#container_path_list=' do
      it 'can be manually assigned' do
        mixin = setup
        list  = ['foo', 'bar', 'baz']
        mixin.container_path_list = list
        expect(mixin.container_path_list).to eq(list)
      end

      it 'fails when list is not an array' do
        mixin = setup
        msg = 'container path list must be an array'
        expect {
          mixin.container_path_list = 'foo'
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#container_path_list?' do
      it 'returns false by default cause no list exists' do
        mixin = setup
        expect(mixin.container_path_list?).to be false
      end

      it 'returns true with a path is assigned' do
        mixin = setup
        mixin.container_path_list = ['foo', 'bar', 'baz']
        expect(mixin.container_path_list?).to be true
      end
    end

    context '#load_path_from_ruby_namespace' do
      it 'assigns container_path_list from the ruby namespace' do
        namespace = 'Foo::BarBaz::Boo'
        mixin = setup
        mixin.load_path_from_ruby_namespace(namespace)
        list = ['foo', 'bar_baz', 'boo']
        expect(mixin.container_path_list).to eq(list)
      end
    end

    context '#load_path_from_container_namespace' do
      it 'assigns container_path_list from the container namespace' do
        namespace = 'foo.bar.biz_baz'
        mixin = setup
        mixin.load_path_from_container_namespace(namespace)
        list = ['foo', 'bar', 'biz_baz']
        expect(mixin.container_path_list).to eq(list)
      end
    end

    context 'default container_path_list' do
      it 'loads the ruby namespace of the object mixed into' do
        namespace = 'Fiz::BarBaz::Boo'
        mixin = setup
        allow(mixin).to receive(:to_s).with(no_args) { namespace }
        list = ['fiz', 'bar_baz', 'boo']
        expect(mixin.container_path_list).to eq(list)
      end
    end

    context 'container_root_key' do
      it 'returns the first key in contain_path_list' do
        mixin = setup
        mixin.container_path_list = ['foo', 'bar', 'baz']
        expect(mixin.container_root_key).to eq('foo')
      end
    end

    context 'global_key' do
      it 'returns the text for global namespace' do
        mixin = setup
        mixin.container_path_list = ['foo', 'bar', 'baz']
        expect(mixin.global_key).to eq('global')
      end
    end

    context 'feature_key' do
      it 'returns the namespace for the feature' do
        mixin = setup
        mixin.container_path_list = ['foo', 'bar', 'baz']
        expect(mixin.feature_key).to eq('features.bar')
      end
    end

    def setup
      obj = Object.new
      obj.extend(ContainerKey)
      obj
    end
  end
end
