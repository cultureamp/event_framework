module EventFramework
  module EventStore
    class EventTypeResolver
      UnknownEventTypeError = Class.new(Error)

      EventTypeDescription = Struct.new(:event_type, :aggregate_type)

      def initialize(event_context_module:)
        @event_context_module = event_context_module
      end

      def serialize(event_class)
        parts = event_class.name.split('::') - event_context_module.name.split('::')
        EventTypeDescription.new(*parts.reverse)
      end

      def deserialize(aggregate_type, event_type)
        raise ArgumentError, "aggregate_type must not be nil" if aggregate_type.nil?

        event_context_module
          .const_get(aggregate_type, false)
          .const_get(event_type, false)
      rescue NameError
        raise UnknownEventTypeError, [aggregate_type, event_type].join('::')
      end

      private

      attr_reader :event_context_module
    end
  end
end
