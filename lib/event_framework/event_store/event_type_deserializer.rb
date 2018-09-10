module EventFramework
  module EventStore
    class EventTypeDeserializer
      UnknownEventType = Class.new(Error)

      def self.call(aggregate_type, event_type)
        raise ArgumentError, "aggregate_type must not be nil" if aggregate_type.nil?

        EventFramework.config.event_namespace_class
          .const_get(aggregate_type, false)
          .const_get(event_type, false)
      rescue NameError
        raise UnknownEventType, [aggregate_type, event_type].join('::')
      end
    end
  end
end
