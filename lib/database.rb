require 'sequel'
require 'erb'
require 'yaml'

module EventFramework
  class EventStore
    def self.database
      @database ||= Sequel.connect(EventFramework.config.database_url).tap do |database|
        database.extension :pg_json
      end
    end
  end
end
