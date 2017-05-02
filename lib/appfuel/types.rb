require 'dry/core/constants'
require 'dry-equalizer'
require 'dry-container'
require 'dry-types'

Dry::Types.load_extensions(:maybe)

module Types
  include Dry::Types.module
  include Dry::Core::Constants

  class << self

    # @param key [String, Symbol]
    # @return [Class]
    def [](key)
      Dry::Types[key]
    end

    # @param key [String, Symbol]
    # @return [Class]
    def key?(key)
      Dry::Types.container.key?(key)
    end

    # Container used to store validation types and domain entities
    #
    # @return Dry::Container
    def container
      Dry::Types.container
    end

    # Register a dependency that can be used for injection
    #
    # @param key [String, Symbol]
    # @param klass [Class]
    # @return
    def register(key, klass)
      container.register(key, klass)
    end

    def register_domain(klass, opts = {})
      unless klass.respond_to?(:domain_name)
        fail "Domain must be a Appfuel::Entity or respond to :domain_name"
      end
      name = opts.key?(:as) ? opt[:as] : klass.domain_name
      return if key?(name) && self[name] == klass

      register(name, klass)
    end
  end
end
