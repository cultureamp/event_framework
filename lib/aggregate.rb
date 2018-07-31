module EventFramework
  class Aggregate
    attr_reader :id, :staged_events

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

    def initialize(id)
      @id = id
      @aggregate_sequence = 0
      @staged_events = []
    end

    def load_events(events)
      events.each do |event|
        handle_event(event)
      end
    end

    def stage_event(domain_event, metadata)
      staged_event = build_staged_event(domain_event, metadata)
      staged_events << staged_event

      handle_event(staged_event)
    end

    private

    attr_reader :aggregate_sequence

    def build_staged_event(domain_event, metadata)
      StagedEvent.new(
        aggregate_id: id,
        aggregate_sequence: aggregate_sequence.next,
        domain_event: domain_event,
        metadata: metadata.to_h,
      )
    end

    def handle_event(event)
      self.class.event_handlers.for(event.domain_event.type).each do |handler|
        case handler.arity
        when 1 then instance_exec(event.domain_event, &handler)
        when 2 then instance_exec(event.domain_event, event.metadata, &handler)
        end
      end

      @aggregate_sequence = event.aggregate_sequence
    end
  end
end
