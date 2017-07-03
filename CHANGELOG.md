# Change Log
All notable changes to this project will be documented in this file. (Pending approval) This project adheres to [Semantic Versioning](http://semver.org/). You can read more on this at [keep a change log](http://keepachangelog.com/)

# [Unreleased]


# Releases
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
