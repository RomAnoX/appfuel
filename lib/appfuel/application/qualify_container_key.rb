module Appfuel
  module Application
    # Mixins to allow you to handle application container keys. The application
    # container operates based on certain conventions which we take into account
    # here.
    module QualifyContainerKey
      # Convert the injection key to a fully qualified namespaced key that
      # is used to pull an item out of the app container.
      #
      # Rules:
      #   1) split the injection key by '.'
      #   2) use the feature_key as the initial namespace
      #   3) when the first part of the key is "global" use that instead of
      #      the feature_key
      #   4) append the type_key to the namespace unless it is "container"
      #      type_key like "repositories" or "commands" removes the need for
      #      the user to have to specify it since they already did that when
      #      they used the type param.
      #
      #
      #   note: feature_key in these examples will be "features.my-feature"
      #   @example of a feature repository named foo
      #
      #       convert_to_qualified_container_key('foo', 'repositories')
      #
      #       returns 'features.my-feature.repositories.foo'
      #
      #   @example of a global command names bar
      #
      #       convert_to_qualified_container_key('global.bar', 'commands')
      #
      #       returns 'gloval.commands.bar'
      #
      #   @example of a container item baz
      #     NOTE: feature container items are not in any namespace, they are any item
      #           that can resolve from the namespace given by "feature_key"
      #
      #      convert_to_qualified_container_key('baz', 'container')
      #
      #      returns 'features.my-feature.baz'
      #
      #   @example of a global container item baz
      #     NOTE: global container items are not in any namespace, they are any item
      #           you can resolve from the application container.
      #
      #     convert_to_qualified_container_key('global.baz', 'container')
      #
      #     returns 'baz'
      #
      # @param key [String] partial key to be built into fully qualified key
      # @param type_ns [String] namespace for key
      # @return [String] fully qualified namespaced key
      def qualify_container_key(key, type_ns)
        parts     = key.to_s.split('.')
        namespace = "#{container_feature_key}."
        if parts[0].downcase == 'global'
          namespace = 'global.'
          parts.shift
        elsif parts[0] == container_feature_name
          parts.shift
        end

        # when the key is a global container the namespace is only the path
        if type_ns == "container"
          namespace = '' if namespace == 'global.'
          type_ns = ''
        else
          type_ns = "#{type_ns}."
        end

        path = parts.join('.')
        "#{namespace}#{type_ns}#{path}"
      end
    end
  end
end
