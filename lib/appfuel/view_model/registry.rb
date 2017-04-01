module Appfuel
  module ViewModel
    module Registry
      def view_models
        @view_models ||= {}
      end

      def view_model?(name)
        view_models.key?(name.to_sym)
      end

      def view_model(name, &blk)
        fail "view models must be used with a block" unless block_given?

        model = build_view_model
        view_models[name] = ->(data, inputs = {}) {
          model.instance_exec(data, inputs, &blk)
        }
      end

      def present_view_model(data, inputs = {})
        return data if inputs[:return_format] == 'raw'

        vm = search_view_model(data, inputs)
        vm.call(data, inputs)
      end

      def search_view_model(data, inputs = {})
        name = inputs.fetch(:view_name) { default_view_name(data) }
        return generc_view_model(data) unless name

        view_model?(name) ? view_models[name] : generic_view_model(data)
      end

      def generic_view_model(data)
        method = case
                 when data.respond_to?(:to_view_model) then :to_view_model
                 when data.respond_to?(:to_h)          then :to_h
                 when data.respond_to?(:to_hash)       then :to_h
                 when data.respond_to?(:to_a)          then :to_a
                 else
                   :to_s
                 end
        ->(result, _inputs = {}) { result.public_send(method) }
      end

      def default_view_name(data)
        return false unless data.respond_to?(:domain_basename)

        name = data.domain_basename
        if data.respond_to?(:collection?) && data.collection?
          name = "#{name}_collection"
        end

        name.to_sym
      end

      def view_model_class
        Base
      end

      def build_view_model
        view_model_class.new(view_model_finder)
      end

      def find_view_model(name)
        unless view_model?(name)
          fail "Could not find view modle name: #{name}"
        end
        view_models[name]
      end

      def view_model_finder
        ->(view_name, entity, inputs = {}) {
          mod = self.find_module(entity.domain_name)
          mod.find_view_model(view_name)
        }
      end
    end
  end
end
