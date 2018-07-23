module EventFramework
  module EventStore
    class Source
      class EventTypeDeserializer
        def self.call(event_type)
          EventFramework.config.event_namespace_class.const_get(event_type)
        end
      end
    end
  end
end
