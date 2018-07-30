EventFramework.configure do |config|
  config.database_url = ENV.fetch('EVENT_STORE_DATABASE_URL', 'postgres://localhost/survey_event_store_test')
end
