module EventFramework
  class EventProcessor
    class << self
      extend Forwardable

      def_delegators :event_classes, :handled_event_classes

      def process(*event_classes, &block)
        event_classes.each do |event_class|
          event_handlers.add(event_class, block)
        end
      end

      def event_handlers
        @event_handlers ||= EventHandlerRegistry.new
      end
    end

    # TODO: Should this take multiple events?
    def process_events(events)
      events.each do |event|
        self.class.event_handlers.for(event.domain_event.type).each do |handler|
          # TODO: Check arity
          instance_exec(event.aggregate_id, event.domain_event, event.metadata, &handler)
        end
      end
    end
  end
end
