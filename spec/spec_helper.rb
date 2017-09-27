require "simplecov"
SimpleCov.start

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end

require 'awesome_print'
require 'appfuel/testing_spec/appfuel_spec_helper'
require_relative 'support/database_cleaner'
require_relative 'support/factory_girl'
