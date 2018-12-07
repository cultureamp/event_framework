# TODO: Delete after configuration re-factor is complete
EventFramework.configure do |config|
  config.database_url = EventFramework::ParameterStoreDatabaseConfiguration.new('production').database_url
end
