module Appfuel
  # The root module is an import concept. It represents the services top most
  # namespace. It is assumed that the root module will have a feature module,
  # its child, and that feature module will have many action classes inside it.
  module RootModule

    def root_module=(value)
      fail "Root module must be a module" unless value.is_a?(Module)
      @root_module = value
    end

    def root_module
      @root_module ||= root_module_const
    end

    protected

    def root_module_const
      name = root_module_name
      unless Kernel.const_defined?(name)
        fail "Root module is not defined (#{name})"
      end

      Kernel.const_get(name)
    end

    def root_module_name
      self.to_s.split("::").first
    end
  end
end
