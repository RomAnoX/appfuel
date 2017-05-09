require_relative 'presenter/base'
module Appfuel
  module Presenter
    def self.present(name, opts = {}, &block)
      key  = Appfuel.expand_container_key(name, 'presenters')
      root = opts[:root] || Appfuel.default_app_name
      app_container = Appfuel.app_container(root)

      presenter = create_presenter(opts[:base_class] || Base, &block)
      app_container.register(key, presenter)
    end

    def self.create_presenter(klass, &block)
      presenter = klass.new
      ->(data, criteria) { presenter.instance_exec(data, criteria, &block) }
    end
  end
end
