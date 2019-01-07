module EventFramework
  module EventStore
    class EventTypeSerializer
      EventTypeDescription = Struct.new(:event_type, :aggregate_type)

      def initialize(event_context_module:)
        @event_context_module = event_context_module
      end

      def call(event_class)
        parts = event_class.name.split('::') - event_context_module.name.split('::')
        EventTypeDescription.new(*parts.reverse)
      end

      private

      attr_reader :event_context_module
    end
  end
end
