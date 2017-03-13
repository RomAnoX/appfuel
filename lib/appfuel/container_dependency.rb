module Appfuel
  module ContainerDependency
    def container_dependencies
      @container_dependencies ||= {}
    end

    def resolve_container(results = Dry::Container.new)
      root = root_module
      fail "top module must be a Module" unless root.is_a?(Module)

      container_dependencies.each do |container_key, result_key|
        key = result_key || container_key
        results.register(key, root.container[container_key])
      end
      results
    end

    def resolve_container_item(key)
      root = root_module
      fail "top module must be a Module" unless root.is_a?(Module)

      root.container[key]
    end

    # Dsl used to declare a dependency that is located in the application
    # container. This is the container that is initialized when the app
    # goes through bootstraping. It is made available to this system
    # via tha action handler.
    #
    # @param name Symbol  the key used in application container
    # @param opts Hash
    #   as:   custom name for this dependency in action container
    def container(name, opts = {})
      container_dependencies[name.to_sym] = opts[:as]
    end
  end
end
