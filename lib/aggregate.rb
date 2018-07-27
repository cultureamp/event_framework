module EventFramework
  class Aggregate
    attr_reader :id
    attr_reader :new_events
    attr_reader :aggregate_sequence

    class << self
      def apply(*event_classes, &block)
        event_classes.each do |event_class|
          event_handlers.add(event_class, block)
        end
      end

      def event_handlers
        @event_handlers ||= EventHandlerRegistry.new
      end
    end

    def initialize(id, event_sink)
      @id = id
      @aggregate_sequence = 0
      @new_events = []
      @event_sink = event_sink
    end

    def add(domain_event)
      handle_event(domain_event)
      @new_events << domain_event
    end

    def load_events(events)
      events.each do |event|
        handle_event(event.domain_event, event.metadata)
        @aggregate_sequence = event.aggregate_sequence
      end
    end

    def clear_new_events
      @clear_new_events.clear
    end

    private

    def handle_event(domain_event, metadata)
      self.class.event_handlers.for(domain_event.type).each do |handler|
        case handler.arity
        when 1 then instance_exec(domain_event, &handler)
        when 2 then instance_exec(domain_event, metadata, &handler)
        end
      end
    end
  end
end
