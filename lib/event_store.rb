require 'sequel'
require 'erb'
require 'yaml'

module EventFramework
  module EventStore
    autoload :Sink, 'event_store/sink'
    autoload :Source, 'event_store/source'

    def self.database
      @database ||= Sequel.connect(EventFramework.config.database_url).tap do |database|
        database.extension :pg_json
      end
    end
  end
end
