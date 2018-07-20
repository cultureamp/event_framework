require 'sequel'
require 'database_cleaner'
require 'event_framework'
require 'database'

RSpec.configure do |config|
  config.before :suite do
    EventFramework::EventStore.database

    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with :truncation
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
