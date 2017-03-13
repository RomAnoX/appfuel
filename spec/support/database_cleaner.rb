require 'database_cleaner'

RSpec.configure do |config|
  config.filter_run_excluding db: true
  config.filter_run_including focus: true
  config.run_all_when_everything_filtered = true

  config.before(:suite) do
    if config.filter.rules.include? :db
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.clean_with(:truncation)
    end
  end

  config.around(:each, db: true) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
