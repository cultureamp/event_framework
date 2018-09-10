require 'sequel'
require 'erb'
require 'yaml'

module EventFramework
  module EventStore
    autoload :EventBuilder, 'event_framework/event_store/event_builder'
    autoload :EventTypeDeserializer, 'event_framework/event_store/event_type_deserializer'
    autoload :EventTypeSerializer, 'event_framework/event_store/event_type_serializer'
    autoload :Sink, 'event_framework/event_store/sink'
    autoload :Source, 'event_framework/event_store/source'

    def self.database
      raise NotImplementedError if EventFramework.config.database_url.nil?
      @database ||= Sequel.connect(EventFramework.config.database_url).tap do |database|
        database.extension :pg_json
      end
    end
  end
end
