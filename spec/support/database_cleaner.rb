require 'sequel'
require 'database_cleaner'
require 'event_framework'

RSpec.configure do |config|
  config.before :suite do
    # pre-emptively connect to the database, in case we haven't already
    EventFramework::EventStore.database

    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean
  end

  config.around :each do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
