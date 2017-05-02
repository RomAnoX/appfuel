module Appfuel
  module Handler
    # Allow handlers to inject domains, commands, repositories or anything
    # that was initialized in the app container. Injections are done in two
    # steps, first, when the class is loaded in memory the declarations are
    # converted into fully qualified container keys and second, when the
    # handler is run they plucked from the app container into a container
    # dedicated to that one execution.
    module InjectDsl
      TYPES = [:domain, :cmd, :repo, :container]

      # Holds a dictionary where the key is the container key and the value
      # is an an optional alias for the name of the injection to be saved
      # as. Injections a separated into two categories because domains are
      # part of the type system (Dry::Types) and therefore kept in its own
      # container "Types", meaning are fetched differently.
      #
      # @return [Hash]
      def injections
        @injections ||= {}
      end

      # Dsl to declare a dependency injection. You can inject one of four
      # types, which are:
      #   domain:     these are domains or value object
      #   cmd:        commands to be run
      #   repo:       repositories to query the persistence layer
      #   container:  any initialized container item
      #
      # since names an collide you can rename your injection with the
      # :as option.
      #
      # @example of using an alias to rename a domain injection
      #   inject :domain, 'member.user', as: :current_user
      #
      # @example of normal domain injection. In this case the name of the
      #          domain with me the base name "user" not "member.user"
      #
      #   inject :domain, 'member.user'
      #
      #
      # @param type [Symbol] type of injection
      # @param key [String, Symbol] container key
      # @param opts [Hash]
      # @option as [String, Symbol] alternate name for injection
      # @return nil
      def inject(type, key, opts = {})
        unless inject_type?(type)
          fail "inject type must be #{TYPES.join(",")} #{type} given"
        end

        cat = case type
              when :repo   then 'repositories'
              when :cmd    then 'commands'
              when :domain then 'domains'
              else
                "container"
              end

        namespaced_key = convert_to_qualified_container_key(key, cat)
        injections[namespaced_key] = opts[:as]
        nil
      end

      def resolve_dependencies(container = Dry::Container.new)
        app_container = Appfuel.app_container
        injections.each do |key, alias_name|
          unless app_container.key?(key)
            fail "Could not inject (#{key}): not registered in app container"
          end

          basename = key.split('.').last
          item = app_container[key]
          container_key = alias_name || basename
          container.register(container_key, item)
        end
      end

      private



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
      def convert_to_qualified_container_key(key, type_ns)
        parts     = key.to_s.split('.')
        namespace = "#{container_feature_key}."
        if parts[0].downcase == 'global'
          namespace = 'global.'
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

      # @param type [Symbol]
      # @return [Bool]
      def inject_type?(type)
        TYPES.include?(type)
      end
    end
  end
end
