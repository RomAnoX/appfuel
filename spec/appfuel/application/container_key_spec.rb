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
        mixin.container_path = list
        expect(mixin.container_path).to eq(list)
      end

      it 'fails when list is not an array' do
        mixin = setup
        msg = 'container path list must be an array'
        expect {
          mixin.container_path = 'foo'
        }.to raise_error(RuntimeError, msg)
      end
    end

    context '#container_path_list?' do
      it 'returns false by default cause no list exists' do
        mixin = setup
        expect(mixin.container_path?).to be false
      end

      it 'returns true with a path is assigned' do
        mixin = setup
        mixin.container_path = ['foo', 'bar', 'baz']
        expect(mixin.container_path?).to be true
      end
    end

    context '#load_path_from_ruby_namespace' do
      it 'assigns container_path_list from the ruby namespace' do
        namespace = 'Foo::BarBaz::Boo'
        mixin = setup
        mixin.load_path_from_ruby_namespace(namespace)
        list = ['foo', 'bar_baz', 'boo']
        expect(mixin.container_path).to eq(list)
      end
    end

    context '#load_path_from_container_namespace' do
      it 'assigns container_path_list from the container namespace' do
        namespace = 'foo.bar.biz_baz'
        mixin = setup
        mixin.load_path_from_container_namespace(namespace)
        list = ['foo', 'bar', 'biz_baz']
        expect(mixin.container_path).to eq(list)
      end
    end

    context 'default container_path_list' do
      it 'loads the ruby namespace of the object mixed into' do
        namespace = 'Fiz::BarBaz::Boo'
        mixin = setup
        allow(mixin).to receive(:to_s).with(no_args) { namespace }
        list = ['fiz', 'bar_baz', 'boo']
        expect(mixin.container_path).to eq(list)
      end
    end

    context 'container_root_name' do
      it 'returns the first key in contain_path_list' do
        mixin = setup
        mixin.container_path = ['foo', 'bar', 'baz']
        expect(mixin.container_root_name).to eq('foo')
      end
    end

    context 'container_global_name' do
      it 'returns the text for global namespace' do
        mixin = setup
        mixin.container_path = ['foo', 'bar', 'baz']
        expect(mixin.container_global_name).to eq('global')
      end
    end

    context 'container_features_root_name' do
      it 'returns "features"' do
        mixin = setup
        expect(mixin.container_features_root_name).to eq('features')

      end
    end

    context 'container_feature_name' do
      it 'returns the name of the feature the 2nd index in container_path' do
        mixin = setup
        path  = ['foo', 'bar', 'baz']
        mixin.container_path = path
        expect(mixin.container_feature_name).to eq(path[1])
      end
    end

    context 'container_feature_key' do
      it 'returns the namespace for the feature' do
        mixin = setup
        mixin.container_path = ['foo', 'bar', 'baz']
        expect(mixin.container_feature_key).to eq('features.bar')
      end
    end


    context 'container_relative_key' do
      it 'returns the relative path from the feature' do
        mixin = setup
        mixin.container_path = ['foo', 'bar', 'baz','biz']
        expect(mixin.container_relative_key).to eq('baz.biz')
      end

      it 'returns the relative path from global' do
        mixin = setup
        mixin.container_path = ['foo', 'global', 'bar']
        expect(mixin.container_relative_key).to eq('bar')
      end
    end

    context 'container_global_path?' do
      it 'returns false with path belongs to a feature' do
        mixin = setup
        mixin.container_path = ['foo', 'bar', 'baz','biz']
        expect(mixin.container_global_path?).to be false
      end

      it 'returns true with a path that has "global" as the second item' do
        mixin = setup
        mixin.container_path = ['foo', 'global', 'baz','biz']
        expect(mixin.container_global_path?).to be true
      end
    end

    context 'top_container_key' do
      it 'returns "global for a global path' do
        mixin = setup
        mixin.container_path = ['foo', 'global', 'baz','biz']
        expect(mixin.top_container_key).to eq('global')
      end

      it 'returns the container_feature_key when it is not global' do
        mixin = setup
        mixin.container_path = ['foo', 'bar', 'baz','biz']
        expect(mixin.top_container_key).to eq('features.bar')
      end
    end

    context 'qualified container key' do
      it 'returns the key in the format top_container_key.relative_container_key' do
        mixin = setup
        mixin.container_path = ['foo', 'bar', 'baz']
        expected_key = "#{mixin.top_container_key}.#{mixin.container_relative_key}"
        expect(mixin.container_qualified_key).to eq(expected_key)
      end

      it 'returns top_container_key.relative_container_key even when global' do
        mixin = setup
        mixin.container_path = ['foo', 'global', 'baz']
        expected_key = "#{mixin.top_container_key}.#{mixin.container_relative_key}"
        expect(mixin.container_qualified_key).to eq(expected_key)
      end
    end

    def setup
      obj = Object.new
      obj.extend(ContainerKey)

      obj
    end
  end
end
