[![Code Climate](https://codeclimate.com/github/rsb/appfuel/badges/gpa.svg)](https://codeclimate.com/github/rsb/appfuel)
[![Test Coverage](https://codeclimate.com/github/rsb/appfuel/badges/coverage.svg)](https://codeclimate.com/github/rsb/appfuel/coverage)
[![Issue Count](https://codeclimate.com/github/rsb/appfuel/badges/issue_count.svg)](https://codeclimate.com/github/rsb/appfuel)

# Appfuel
Appfuel is a library that employs a set of conventions and patterns used to separate your business code from the API framework in which it lives, while providing a consistent interface for your api code to interact with it. The idea is that your business code should live isolated in its own gem making the api boundary, your rails app for example, just another client..


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'appfuel'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install appfuel

## Usage


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/appfuel. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

