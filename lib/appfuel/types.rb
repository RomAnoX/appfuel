require 'dry/core/constants'
require 'dry-equalizer'
require 'dry-container'
require 'dry-types'

Dry::Types.load_extensions(:maybe)

module Types
  include Dry::Types.module
  include Dry::Core::Constants

  # Allows active record models to be used through dependency. This is used
  # by repositories when mapping active record models to domain entities.
  module Db
    class << self

      # Container used to store db dependencies
      #
      # @return Dry::Container
      def container
        @container ||= Dry::Container.new
      end

      # Register a dependency that can be used for injection
      #
      # @param key [String, Symbol]
      # @param klass [Class]
      # @return
      def register(key, klass)
        container.register(key, klass)
      end

      # @param key [String, Symbol]
      # @return [Class]
      def [](key)
        container[key]
      end

      # @param key [String, Symbol]
      # @return [Bool]
      def key?(key)
        container.key?(key)
      end
    end
  end

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
