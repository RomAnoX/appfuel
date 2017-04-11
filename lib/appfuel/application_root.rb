module Appfuel
  module ApplicationRoot
    def container
      Appfuel.container[app_name]
    end

    def app_name
      container[:app_name]
    end

    # 1) create a dry container namespace using the app name
    #   a) if no name is given parse the root module,
    #      decoded into lowercase underscore and use that as the name
    #
    # 2) assign the root module & path into that namespace
    #    note: all di assignments will be made with this key, we should
    #    propably cache the app_name and wrap DI access
    #
    # 3) resolve configuration data into a hash and assign it to
    #    the di container with namespace <app_name>.config
    #    a) check for method <config_definition> on the root module
    #       use that definition to populate the config
    #     b) when no definition exists look for config_data method
    #     c) when no config data use an empty hash
    #
    # 4) run initializers. fire off method load_initializers on root
    #   module. This will give the library to do a require for the
    #   correct order of initializers.
    #
    #   Initializer Dsl
    #     1) add initializer block to initializer registry
    #     2) initializer stack is a FIFO stack
    #     3) order is controlled my a main initializer.rb file that is required when
    #        the hook is fired
    #     4) an initializer accepts a container
    def setup(data = {})
      root = data.fetch(:root_module) {
        fail "A root module is required to setup Appfuel"
      }

      name = root_module.to_s.underscore
      container.register(:default_app_name, name)

      app_container = Dry::Container.new
      app_container.register(:root_path, path)
      app_container.register(:root_module, root)
      app_container.register(:initializers, ThreadSafe::Array.new)
      app_container.register(:config_definition, root.cofiguration_definition)

      container.register(name, app_container)
      root.load_initializers

      app_container
    end
  end
end
