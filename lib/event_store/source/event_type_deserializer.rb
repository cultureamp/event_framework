module EventFramework
  module EventStore
    class Source
      class EventTypeDeserializer
        UnknownEventType = Class.new(Error)

        def self.call(event_type)
          EventFramework.config.event_namespace_class.const_get(event_type)
        rescue NameError
          raise UnknownEventType, event_type
        end
      end
    end
  end
end
