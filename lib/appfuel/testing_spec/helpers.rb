module Appfuel
  module TestingSpec
    module Helpers
      def allow_const_defined_as_true(mod, name)
        allow_const_defined(mod, name, true)
      end

      def allow_const_defined_as_false(mod, name)
        allow_const_defined(mod, name, false)
      end

      def allow_const_defined(mod, name, result)
        allow(mod).to receive(:const_defined?).with(name) { result }
      end

      def allow_const_get(mod, name, result)
        allow(mod).to receive(:const_get).with(name) { result }
      end

      def build_container(data = {})
        container = Dry::Container.new
        data.each {|key, value| container.register(key, value)}
        container
      end

      def allow_type(name, type)
        allow(Types).to receive(:key?).with(name) { true }
        allow(Types).to receive(:[]).with(name) { type }
        type
      end

      def allow_domain_type(name, type)
        basename = name.to_s.split('.').last
        allow_type(name, type)
        allow(type).to receive(:domain_name).with(no_args) { name }
        allow(type).to receive(:domain_basename).with(no_args) { basename }
        type
      end

      def allow_db_type(name, type)
        allow(Types::Db).to receive(:key?).with(name) { true }
        allow(Types::Db).to receive(:[]).with(name) { type }
      end

      def allow_db_column_names(db_class, cols)
        allow(db_class).to receive(:column_names).with(no_args) { cols }
      end

      def allow_db_entity_attributes(db_class, hash)
        allow(db_class).to receive(:entity_attributes).with(no_args) { hash }
      end

      def mock_db_class(name, cols = [])
      end
    end
  end
end
