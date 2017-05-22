module Appfuel::Db
  RSpec.describe ActiveRecordModel do
    it 'is an abstract class' do
      expect(model_class.abstract_class).to be(true)
    end

    it 'has a container_class_type of "db"' do
      expect(model_class.container_class_type).to eq('db')
    end

    context '.inherited' do
      it 'registers a model in the container' do
        container = build_container(auto_register_classes: [])
        model = setup(container, 'FooApp::BarFeature::Db::MyModel')
        expect(container[:auto_register_classes]).to include(model)
      end
    end

    context '#domain_attrs' do
      it 'symobilzes keys and removes nils from active record #attributes' do
        container   = build_container(auto_register_classes: [])
        model_class = setup(container, 'FooApp::BarFeature::Db::MyModel')

        # NOTE: active record is coupled to its connection pool making it
        #       very hard to mock just the attributes without making a db
        #       connection
        allow(ActiveRecord::Base).to receive(:load_schema!) { {} }
        allow(ActiveRecord::Base).to receive(:table_exists?) { true }

        model = model_class.new

        attrs = { 'a' => 'a', 'b' => 'b', 'c' => 'c', 'd' => nil, 'e' => nil}
        # we disable active record attributes so we are faking it here
        model.define_singleton_method(:attributes) do
          attrs
        end

        expected_hash = {a: 'a', b: 'b', c: 'c'}
        expect(model.domain_attrs).to eq(expected_hash)
      end
    end

    def setup(container, class_name)
      allow(Appfuel).to receive(:app_container) { container }
      allow(model_class).to receive(:to_s) { class_name }
      Class.new(model_class)
    end

    def model_class
      ActiveRecordModel
    end
  end
end
