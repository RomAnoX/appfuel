module Appfuel::WebApi
  RSpec.describe HttpModel do

    it 'has a container_class_type of "web_api"' do
      expect(model_class.container_class_type).to eq('web_api')
    end

    context '.inherited' do
      it 'registers a model in the container' do
        container = build_container(auto_register_classes: [])
        model     = setup('FooApp::BarFeature::WebApi::MyModel', container)
        expect(container[:auto_register_classes]).to include(model)
      end
    end

    context 'config_key' do
      it 'assigns a key to be used when loading  its configuration' do
        model = setup('Global::WebApi::MyModel')
        model.config_key :foo

        expect(model.config_key).to eq(:foo)
      end

      it 'does not assign a config key by default' do
        model = setup('Global::WebApi::MyModel')
        expect(model.config_key).to eq(nil)
      end
    end

    context '.load_config' do
      it 'loads the config from the app container with the config key' do
        container = build_container(
          auto_register_classes: [],
          config: {
            fooish: {foo: 'bar'}
          }
        )
        model = setup('Global::WebApi::MyModel', container)
        model.config_key :fooish
        expect(model.load_config).to eq(container[:config][:fooish])

      end
    end

    context 'initialize' do
      it 'initializes with the api url from config' do
        container = build_container(
          auto_register_classes: [],
          config: {
            fooish: {url: 'http://foo.com'}
          }
        )
        model_class = setup('Global::WebApi::MyModel', container)
        model_class.config_key :fooish
        model = model_class.new
        expected_url = URI(container[:config][:fooish][:url])

        default_adapter = RestClient
        expect(model.config).to eq(container[:config][:fooish])
        expect(model.url).to eq(expected_url)
        expect(model.adapter).to eq(default_adapter)
      end
    end


    def setup(class_name, container = nil)
      container ||= build_container(auto_register_classes: [])
      allow(Appfuel).to receive(:app_container) { container }
      allow(model_class).to receive(:to_s) { class_name }
      Class.new(model_class)
    end

    def model_class
      HttpModel
    end
  end
end
