# Change Log
All notable changes to this project will be documented in this file. (Pending approval) This project adheres to [Semantic Versioning](http://semver.org/). You can read more on this at [keep a change log](http://keepachangelog.com/)

# [Unreleased]


# Releases
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
