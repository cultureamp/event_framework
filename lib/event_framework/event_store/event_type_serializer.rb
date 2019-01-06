module EventFramework
  module EventStore
    class EventTypeSerializer
      EventTypeDescription = Struct.new(:event_type, :aggregate_type)

      def initialize(event_container:)
        @event_container = event_container
      end

      def call(event_class)
        parts = event_class.name.split('::') - event_container.name.split('::')
        EventTypeDescription.new(*parts.reverse)
      end

      private

      attr_reader :event_container
    end
  end
end
