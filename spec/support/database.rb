require 'sequel'
require 'database_cleaner'

RSpec.configure do |config|
  config.before :suite do
    TestDomain.databases.each do |database|
      DatabaseCleaner[:sequel, { connection: database.connection }]
    end

    DatabaseCleaner.strategy = :truncation
  end

  config.around :each do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
