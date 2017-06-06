# Third party dependencies
require "json"
require "dry-validation"
require "active_record"

require "appfuel/version"

# Appfuel framework for Action/Comand pattern
require "appfuel/types"
require "appfuel/errors"
require "appfuel/run_error"

require "appfuel/configuration"
require "appfuel/application"
require "appfuel/initialize"
require "appfuel/feature"

# Action/command input/output interfaces
require "appfuel/response"
require "appfuel/response_handler"
require "appfuel/request"

# Custom predicates & validators
require "appfuel/predicates"
require "appfuel/validation"

# Interface for dscribing domain queries

# Dependency management for actions, commands and repos
require "appfuel/root_module"

module Appfuel
  # The appfuel top level interface mainly deals with interacting with both
  # the application dependency injection container and the framework di
  # container.
  class << self
    attr_writer :framework_container

    # The framework dependency injection container holds information
    # specific to appfuel plus an app container for each app it will manage.
    # While it is most common to has only a single app it is designed to
    # host multiple app since all there dependencies are contained in one
    # container.
    #
    # @return [Dry::Container]
    def framework_container
      @framework_container ||= Dry::Container.new
    end


    # The default app name must exist and the container must be registered
    # for this to be true
    #
    # @return [Bool]
    def default_app?
      framework_container.key?(:default_app_name) &&
        framework_container.key?(framework_container[:default_app_name])
    end

    # Used when retrieving, resolving an item from or registering an item
    # with an application container without using its name. The default
    # app is considered the main app where all others have to be specified
    # manually. This is assigned during setup via the module
    # Appfuel::Initialize::Setup
    #
    # @raises Dry::Container::Error when default_app_name is not registered
    #
    # @return [String]
    def default_app_name
      framework_container[:default_app_name]
    end

    # The application container is a di container used to hold all dependencies
    # for the given application.
    #
    # @raises Dry::Container::Error when name is not registered
    #
    # @param name [String, Nil]  default name is used when name is nil
    # @return [Dry::Container]
    def app_container(name = nil)
      framework_container[name || default_app_name]
    end

    # Resolve an item out of the application container
    #
    # @raises RuntimeError when container does not implement :resolve
    # @raises Dry::Container::Error when key is not registered
    # @raises Dry::Container::Error when app_name is not registered
    #
    # @param key [String] key of the item in the app container
    # @param app_name [String, Nil] name of the app container
    # @return the item that was resolved with name
    def resolve(key, app_name = nil)
      di = app_container(app_name)
      unless di.respond_to?(:resolve)
        fail "Application container (#{app_name}) does not implement :resolve"
      end
      di.resolve(key)
    end


    # Register an item in the application container
    #
    # @raises RuntimeError when container does not implement :register
    # @raises Dry::Container::Error when key is not registered
    # @raises Dry::Container::Error when app_name is not registered
    #
    # @param key [String] key of the item in the app container
    # @param app_name [String, Nil] name of the app container
    # @return the item that was resolved with name
    def register(key, value, app_name = nil)
      di = app_container(app_name)
      unless di.respond_to?(:register)
        fail "Application container (#{app_name}) does not implement :register"
      end
      di.register(key, value)
    end


    def setup_container_dependencies(namespace_key, container)
      container.namespace(namespace_key) do
        register('initializers', ThreadSafe::Array.new)
        register('validators', {})
        register('repositories', {})
        register('validator_pipes', {})
        register('domain_builders', {})
        register('presenters', {})
      end
      container
    end

    # Run all initializers registered in the app container
    #
    # @param container [Dry::Container] application container
    # @param app_name [String] name of the app for errors
    # @param params [Hash]
    # @option excludes [Array] list of initializers to exclude from running
    # @return [Dry::Container] same container passed in
    def run_initializers(key, container, exclude = [])
      unless exclude.is_a?(Array)
        fail ArgumentError, ":exclude must be an array"
      end
      exclude.map! {|item| item.to_s}

      env     = container[:env]
      config  = container[:config]
      #runlist = container["#{key}.initializers.run"]

      container["#{key}.initializers"].each do |init|
        if !init.env_allowed?(env) || exclude.include?(init.name)
          next
        end

        begin
          init.call(config, container)
        rescue => e
          app_name = container[:app_name]
          msg = "[Appfuel:#{app_name}] Initialization FAILURE - " + e.message
          error = RuntimeError.new(msg)
          error.set_backtrace(e.backtrace)
          raise error
        end
      end
      container.register("#{key}.initialized", true)

      container
    end

    # memberships.user => features.memberships.presenters.user
    # global.user      => global.presenters.user
    #
    # array
    #   global
    #   user
    #
    # array
    #   membership
    #   user
    def presenter(key, opts = {}, &block)
      key = expect_container_key(key, 'presenters')
      container = app_container(root_name | default_app_name)

      container.register(key, '')

    end

    def expand_container_key(key, category)
      parts = key.to_s.split('.')
      parts.insert(1, category)
      if parts.first != 'global'
        parts.unshift('features')
      end
      parts.join('.')
    end

  end
end

# Domain Entities
require "appfuel/domain"
require "appfuel/presenter"
require "appfuel/storage"
require "appfuel/handler"



