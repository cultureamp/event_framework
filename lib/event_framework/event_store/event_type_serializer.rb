module EventFramework
  module EventStore
    class EventTypeSerializer
      EventTypeDescription = Struct.new(:event_type, :aggregate_type)

      def self.call(event_class)
        parts = event_class.to_s.split('::') - EventFramework.config.event_namespace_class.to_s.split('::')
        EventTypeDescription.new(*parts.reverse)
      end
    end
  end
end
