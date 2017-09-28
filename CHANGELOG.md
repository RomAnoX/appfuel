# Change Log
All notable changes to this project will be documented in this file. (Pending approval) This project adheres to [Semantic Versioning](http://semver.org/). You can read more on this at [keep a change log](http://keepachangelog.com/)

# [Unreleased]


# Releases
## [[0.6.13]](https://github.com/rsb/appfuel/releases/tag/0.6.13) 2017-09-27
### Fixed
- appfuel app_container was not properly being reset during tests

## [[0.6.12]](https://github.com/rsb/appfuel/releases/tag/0.6.12) 2017-09-27
### Added
- appfuel/testing_spec/appfuel_spec_helper adding rspec helpers for other
  libraries to use.

## [[0.6.10]](https://github.com/rsb/appfuel/releases/tag/0.6.10) 2017-09-21
### Added
- adding error handling lambda that can be injected into the container and used
  in the two different rescue blocks of the dispatcher

## [[0.6.9]](https://github.com/rsb/appfuel/releases/tag/0.6.9) 2017-09-12
### Fixed
- `web_api` fix content_type check for json

## [[0.6.8]](https://github.com/rsb/appfuel/releases/tag/0.6.8) 2017-08-24
### Fixed
- `batch_get` typo fixed in dynamodb params requested_items to request_items

## [[0.6.7]](https://github.com/rsb/appfuel/releases/tag/0.6.7) 2017-08-24
### Fixed
- `batch_get` should not return when a block is given

## [[0.6.6]](https://github.com/rsb/appfuel/releases/tag/0.6.6) 2017-08-23
### Added
- `batch_get` to dynamodb nosql adapter

## [[0.6.5]](https://github.com/rsb/appfuel/releases/tag/0.6.5) 2017-08-21
### Added
- basic table query interface for dynamodb nosql adapter

## [[0.6.4]](https://github.com/rsb/appfuel/releases/tag/0.6.4) 2017-08-18
### Fixed
- invalid reference to `feature_name` in action's `dispatch`

### Changed
- `handlers` will now always deep symbolize their input keys

### Added
- `repository` now has a `timestamp` which gives `Time.now.utc.iso8601`

## [[0.6.3]](https://github.com/rsb/appfuel/releases/tag/0.6.3) 2017-08-14
### Fixed
- invalid method is web_api/http_model when checking url

## [[0.6.2]](https://github.com/rsb/appfuel/releases/tag/0.6.2) 2017-08-14
### Fixed
- storage/repository/web_api/http_model missing check for url '/' when
  appending relative paths

## [[0.6.0]](https://github.com/rsb/appfuel/releases/tag/0.6.0) 2017-08-10
### Added
- Validation to handlers
- Dispatching actions to other actions added to the handler
- New mixin `Application::FeatureHelper` to aid in feature initialization

## [[0.5.16]](https://github.com/rsb/appfuel/releases/tag/0.5.16) 2017-08-08
### Fixed
- response handler no longer has double error keys

## [[0.5.15]](https://github.com/rsb/appfuel/releases/tag/0.5.15) 2017-08-08
### Added
- added url_token to base repo

## [[0.5.14]](https://github.com/rsb/appfuel/releases/tag/0.5.14) 2017-08-01
### Fixed
- fixed incorrect undefined check inside entity

## [[0.5.13]](https://github.com/rsb/appfuel/releases/tag/0.5.13) 2017-08-01
### Fixed
- when you override an entity attribute it fails to initialize when value is
  undefined

## [[0.5.12]](https://github.com/rsb/appfuel/releases/tag/0.5.12) 2017-07-31
### Fixed
- `dynamodb adapter` `index` does not check for existing prefix

## [[0.5.11]](https://github.com/rsb/appfuel/releases/tag/0.5.11) 2017-07-31
### Fixed
- `dynamodb adapter` primary_key dsl suppose to be a getter and a setter

## [[0.5.10]](https://github.com/rsb/appfuel/releases/tag/0.5.10) 2017-07-28
### Added
- Primary key object for dynamodb
- new adapter interfaces for get, put, and delete

## [[0.5.9]](https://github.com/rsb/appfuel/releases/tag/0.5.9) 2017-07-27
### Added
- Adding a `run!` to handler which deals with failures
- Adding a HandlerFailure has for when the handler fails
- New interfaces for the aws dynamo db adapter

### Fixed
- Domain dsl attribute with  array member and default is now working
- Updating dry-validations & dry-types

## [[0.5.8]](https://github.com/rsb/appfuel/releases/tag/0.5.8) 2017-07-20
### Fixed
- aws dynamodb initializer region was not being set
- dynamodb repo did not have to_entity or storage_class

## [[0.5.7]](https://github.com/rsb/appfuel/releases/tag/0.5.7) 2017-07-18
### Changed
- domain entity `attr_typed!` will always converts the type name to a symbol

### Fixed
- web_api http model handles exceptions
- fixed `entity_value` in repo mapper it had an old interface
- mapping_dsl was missing `skip` property

## [[0.5.6]] (https://github.com/rsb/appfuel/releases/tag/0.5.6) 2017-07-11
### Fixed
- Fixed registering classes in the feature initializer, it now skips when
  already registered

## [[0.5.5]] (https://github.com/rsb/appfuel/releases/tag/0.5.5) 2017-07-11
### Fixed
- Fixed web_api error handling, re-raised exception incorrectly

## [[0.5.4]] (https://github.com/rsb/appfuel/releases/tag/0.5.4) 2017-07-11
### Fixed
- Fixed error key usage in response handler

## [[0.5.3]] (https://github.com/rsb/appfuel/releases/tag/0.5.3) 2017-07-10
### Fixed
- response object not working when `ok` key is a string

## [[0.5.2]] (https://github.com/rsb/appfuel/releases/tag/0.5.2) 2017-07-03
### Fixed
- aws initialization fails when no endpoint

## [[0.5.1]] (https://github.com/rsb/appfuel/releases/tag/0.5.1) 2017-07-03
### Added
- table prefix to aws_dynamodb nosql_model

## [[0.5.0]] (https://github.com/rsb/appfuel/releases/tag/0.5.0) 2017-06-29
### Added
- adding new repository type of aws dynamodb
- adding initializers for aws dynamodb

### Fixed
- bootstrapping the app is not idempotent and does not throw any errors when
  done twice

### Changed
- storage mapping as simplified to a one-to-one between domain and storage model

## [[0.4.5]] (https://github.com/rsb/appfuel/releases/tag/0.4.5) 2017-06-29
### Fixed
- fixed active record migrator, was not updating config properly

## [[0.4.4]] (https://github.com/rsb/appfuel/releases/tag/0.4.4) 2017-06-21
### Changed
- upgraded `active record to 5.1.1`

### Fixed
- invalid require statement for logging initializer
- invalid container key for web_api initializer

## [[0.4.3]](https://github.com/rsb/appfuel/releases/tag/0.4.3) 2017-06-21
### Fixed
- db config definition referenced invalid namespace

## [[0.4.2]](https://github.com/rsb/appfuel/releases/tag/0.4.2) 2017-06-21
### Added
- database configuration definition

## [[0.4.1]](https://github.com/rsb/appfuel/releases/tag/0.4.1) 2017-06-21
### Changed
- renamed `Appfuel::Configuration` to `Appfuel::Config`

## [[0.4.0]](https://github.com/rsb/appfuel/releases/tag/0.4.0) 2017-06-21
### Added
- logging, db and `web_api` initializers have been added
- added log formatter

## [[0.3.4]](https://github.com/rsb/appfuel/releases/tag/0.3.4) 2017-06-20
### Changed
- `web api model` changed `url` to `uri`
### Added
- `web api model` added `url` method to create full endpoint with path
- `web api model` added `get` and `post` to wrap rest-client interface

## [[0.3.3]](https://github.com/rsb/appfuel/releases/tag/0.3.3) 2017-06-20
### Added
- `storage_hash` method to general mapper

## [[0.3.2]](https://github.com/rsb/appfuel/releases/tag/0.3.2) 2017-06-20
### Fixed
- `mapping_dsl` invalid storage key fixed to `web_api` from `webapi`

## [[0.3.1]](https://github.com/rsb/appfuel/releases/tag/0.3.1) 2017-06-20
### Fixed
- `mapping_dsl` was missing `web_api`
## [[0.3.0]](https://github.com/rsb/appfuel/releases/tag/0.3.0) 2017-06-20
### Added
- adding `web_api` storage to be used for WebApi repositories. The default
  http adapter will be `RestClient`

## [[0.2.11]](https://github.com/rsb/appfuel/releases/tag/0.2.9) 2017-06-15
### Changed
- Adding error handling to dispatching. Errors are converted to responses

## [[0.2.10]](https://github.com/rsb/appfuel/releases/tag/0.2.9) 2017-06-14
### Fixed
- configuration delete was using string for the key, corrected to symbol

## [[0.2.9]](https://github.com/rsb/appfuel/releases/tag/0.2.8) 2017-06-14
### Changed
- configuration now resolve to symbols as keys, children included

## [[0.2.8]](https://github.com/rsb/appfuel/releases/tag/0.2.8) 2017-06-07
### Fixed
- searching configuration definitions with a symbol was failing because key was
  a string

## [[0.2.7]](https://github.com/rsb/appfuel/releases/tag/0.2.7) 2017-06-07
### Changed
- Initializers are now stored in the app container and separate runlist
  determines the order for which they run

## [[0.2.6]](https://github.com/rsb/appfuel/releases/tag/0.2.6) 2017-06-06
### Added
- dispatcher mixin

### Changed
- moved domain parsing to repository namespace
## [[0.2.5]](https://github.com/rsb/appfuel/releases/tag/0.2.5) 2017-05-23
### Fixed
- feature initializer has invalid reference `register?`
- search criteria did not have `order_expr`

### Added
- tests for search criteria `filter`

## [[0.2.4]](https://github.com/rsb/appfuel/releases/tag/0.2.4) 2017-05-23
### Changed
- `Appfuel::Domain::BaseCriteria` can now qualify `domain exprs`
- refactored and tested repo mapper
- starting to work on db mapper interfaces


### Added
- added exists interface to db mapper, will finalize the repo on next release
