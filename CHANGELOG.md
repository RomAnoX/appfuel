# Change Log
All notable changes to this project will be documented in this file. (Pending approval) This project adheres to [Semantic Versioning](http://semver.org/). You can read more on this at [keep a change log](http://keepachangelog.com/)

# [Unreleased]

# Releases
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

## [[0.2.6]](https://github.com/rsb/appfuel/releases/tag/0.2.6) 2017-06-6

### Added
- dispatcher mixin

### Changed
- moved domain parsing to repository namespace
