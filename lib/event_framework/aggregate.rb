module EventFramework
  class Aggregate
    attr_reader :id, :staged_events

    class << self
      def new(*)
        raise NotImplementedError, "Please use #{name}.build(id) to create an instance of #{name}"
      end

      def apply(*event_classes, &block)
        event_classes.each do |event_class|
          event_handlers.add(event_class, block)
        end
      end

      def event_handlers
        @event_handlers ||= EventHandlerRegistry.new
      end

      def build(id)
        allocate.tap do |aggregate|
          aggregate.instance_variable_set(:@id, id)
          aggregate.instance_variable_set(:@aggregate_sequence, 0)
          aggregate.instance_variable_set(:@staged_events, [])

          aggregate.send(:initialize)
        end
      end
    end

    def load_events(events)
      events.each do |event|
        handle_event(event)
      end
    end

    def stage_event(domain_event)
      staged_event = build_staged_event(domain_event)
      staged_events << staged_event

      handle_event(staged_event)
    end

    private

    attr_reader :aggregate_sequence

    def build_staged_event(domain_event)
      StagedEvent.new(
        aggregate_id: id,
        aggregate_sequence: aggregate_sequence.next,
        domain_event: domain_event,
        mutable_metadata: nil,
      )
    end

    def handle_event(event)
      self.class.event_handlers.for(event.domain_event.type).each do |handler|
        instance_exec(event.domain_event, &handler)
      end

      @aggregate_sequence = event.aggregate_sequence
    end
  end
end
