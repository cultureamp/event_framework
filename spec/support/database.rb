require 'sequel'
require 'database_cleaner'
require 'event_framework'

module EventFramework
  def self.test_database
    @_test_database ||= Sequel.connect(RSpec.configuration.database_url).tap do |database|
      database.extension :pg_json
    end
  end
end

RSpec.configure do |config|
  # connect to an isolated database when running EventFramework specs
  config.add_setting :database_url, default: ENV.fetch('EVENT_FRAMEWORK_TEST_DATABASE_URL', 'postgres://localhost/event_framework_test_database')

  config.before :suite do
    # prepare the framework test database
    connection = EventFramework::DatabaseConnection.new(:framework_test)
    connection.connection_url = config.database_url

    database_manager = EventFramework::Tasks::DatabaseManager.new(connection)
    database_manager.drop
    database_manager.create
    database_manager.migrate migrations_path: Pathname.new(__dir__).join('db'), target_version: nil

    # set up database cleaner
    DatabaseCleaner[:sequel].db = EventFramework.test_database
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean
  end

  config.around :each do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
