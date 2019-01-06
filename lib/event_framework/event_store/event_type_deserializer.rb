module EventFramework
  module EventStore
    class EventTypeDeserializer
      UnknownEventType = Class.new(Error)

      def initialize(event_container:)
        @event_container = event_container
      end

      def call(aggregate_type, event_type)
        raise ArgumentError, "aggregate_type must not be nil" if aggregate_type.nil?

        event_container
          .const_get(aggregate_type, false)
          .const_get(event_type, false)
      rescue NameError
        raise UnknownEventType, [aggregate_type, event_type].join('::')
      end

      private

      attr_reader :event_container
    end
  end
end
