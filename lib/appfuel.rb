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

# Action/command input/output interfaces
require "appfuel/response"
require "appfuel/response_handler"
require "appfuel/request"
require "appfuel/dispatcher"

# Custom predicates & validators
require "appfuel/predicates"
require "appfuel/validators"

# Domain Entities
require "appfuel/domain"

require "appfuel/db_model"

# Interface for dscribing domain queries
require "appfuel/pagination"

require "appfuel/application_root"

# Dependency management for actions, commands and repos
require "appfuel/root_module"
require "appfuel/validator_dependency"
require "appfuel/container_dependency"
require "appfuel/command_dependency"
require "appfuel/repository_dependency_injection"

require "appfuel/view_model"

# Database entity mapping
require "appfuel/db"
require "appfuel/repository_runner"

# callable operations
require "appfuel/handler"
require "appfuel/command"
require "appfuel/interactor"

module Appfuel
  def self.container
    @container ||= Dry::Container.new
  end
end

# Appfuel
#   container
#     service
#       name
#       root_module
#       root_path
#
=begin
  configure_service do |config|
    config.root_module  = SpService
    config.root_path    = ROOT_PATH
    config.db_maps      =
    config.initializers =
    config.config_files = [

    ]
  end

  features do
    authentication
    audits
    user_management
  end

  collect configure
  run app initializer

  #
  # this should probably lazy loaded when
  # the feature is first accessed
  #
=end
