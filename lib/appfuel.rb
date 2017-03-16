
# Third party dependencies
require "json"
require "dry-validation"
#require "active_model/errors"
require "active_record"

require "appfuel/version"

# Appfuel framework for Action/Comand pattern
require "appfuel/types"
require "appfuel/errors"
require "appfuel/run_error"

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
require "appfuel/pager"
require "appfuel/criteria"
require "appfuel/entity_expr"

# Dependency management for actions, commands and repos
require "appfuel/root_module"
require "appfuel/validator_dependency"
require "appfuel/container_dependency"
require "appfuel/domain_dependency"
require "appfuel/command_dependency"
require "appfuel/repository_dependency"

# Database entity mapping
require "appfuel/db_entity_map_dsl"
require "appfuel/db_entity_map"
require "appfuel/db_entity_map_entry"
require "appfuel/db_mapping_registry"
require "appfuel/db_entity_mapper"
require "appfuel/repository_mapping"
require "appfuel/repository"
require "appfuel/repository_runner"

# callable operations
require "appfuel/handler"
require "appfuel/command"
require "appfuel/action"
