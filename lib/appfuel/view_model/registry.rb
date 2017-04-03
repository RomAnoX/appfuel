module Appfuel
  module ViewModel
    # The registry builds and stores all view models. It also has the
    # interfaces for find view models. It is important to note that
    # the registry makes the assumption that view models will be stored
    # either at the root module or the feature module and takes that into
    # account when trying to locate them.
    #
    module Registry

      # Hash of all view models keyed by name
      #
      # @return [Hash]
      def view_models
        @view_models ||= {}
      end

      # @param name [Symbol, String]
      # @return [Boolean]
      def view_model?(name)
        view_models.key?(name.to_sym)
      end

      # Dsl method used to store a reference to the block and change
      # its context to whatever class the method `view_model_class` returns.
      # This is captured in a lamda and stored with the given name
      #
      # @raise [RuntimeError] when no block is given
      #
      # @param name [Symbol, String]
      # @return [lamda]
      def view_model(name, &blk)
        fail "view models must be used with a block" unless block_given?

        model = build_view_model
        name  = name.to_sym
        view_models[name] = ->(data, inputs = {}) {
          model.instance_exec(data, inputs, &blk)
        }
      end

      # This is generally used by the interactor as the final step of
      # preparing the data to be returned.
      #
      # @param dataset [mixed] Anything the view model knows how to work with
      # @param inputs [Hash] control inputs
      # @return Hash
      def present_view_model(dataset, inputs = {})
        return dataset if inputs[:return_format] == 'raw'

        vm = find_view_model(dataset, inputs)
        vm.call(dataset, inputs)
      end

      # locates a view model to transform the dataset. If the view model is
      # not found a generic one is given.
      #
      # @param dataset [mixed]
      # @param inputs [Hash] control inputs
      # @return lamda
      def find_view_model(dataset, inputs = {})
        mod  = view_model_module(dataset, inputs)
        name = inputs.fetch(:view_name) { default_view_name(dataset) }
        return generc_view_model(data) unless name

        unless mod.view_model?(name)
          return mod.generic_view_model(data)
        end

        mod.view_models[name]
      end

      # Determines if the view model is located in this registry or the global
      # one and returns a reference to it
      #
      # @param dataset [mixed]
      # @param inputs [Hash]
      # @return the root module or self
      def view_model_module(dataset, inputs = {})
        return root_module if inputs[:global_view] == true
        return root_module if dataset.respond_to?(:global?) && dataset.global?
        self
      end

      # Determines how to transform the dataset when no info is given.
      #
      # @param dataset [mixed]
      # @return lambda
      def generic_view_model(dataset)
        method = case
                 when dataset.respond_to?(:to_view_model) then :to_view_model
                 when dataset.respond_to?(:to_h)          then :to_h
                 when dataset.respond_to?(:to_hash)       then :to_hash
                 when dataset.respond_to?(:to_a)          then :to_a
                 else
                   :to_s
                 end
        ->(result, _inputs = {}) { result.public_send(method) }
      end

      # Automatically names the view model for entity interfaces
      #
      # @param dataset [Appfuel::Domain::Base]
      # @return [Symbol, FalseClass]
      def default_view_name(dataset)
        return false unless dataset.respond_to?(:domain_basename)

        name = dataset.domain_basename
        if dataset.respond_to?(:collection?) && dataset.collection?
          name = "#{name}_collection"
        end

        name.to_sym
      end

      # This will be the class used to call `instance_exec` for the
      # view model block
      #
      # @return Appfuel::ViewModel::Base
      def view_model_class
        Base
      end


      # Building the view model class
      #
      # @return Appfuel::ViewModel::Base
      def build_view_model
        view_model_class.new(view_model_finder)
      end

      # Find used by the view model class to locate other view models
      #
      # @return [lamda]
      def view_model_finder
        @view_model_fined ||= ->(dataset, inputs = {}) {
          self.find_view_model(dataset, inputs)
        }
      end
    end
  end
end
