module EventFramework
  class Aggregate
    attr_reader :id

    class StagedEvent < Dry::Struct
      attribute :aggregate_id, Types::UUID
      attribute :aggregate_sequence, Types::Strict::Integer
      attribute :domain_event, DomainEvent

      attribute :metadata do
        transform_keys(&:to_sym)

        attribute :account_id, Types::UUID
        attribute :user_id, Types::UUID
        attribute :correlation_id, Types::UUID.meta(omittable: true)
        attribute :causation_id, Types::UUID.meta(omittable: true)
      end
    end

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
      @staged_events = []
      @event_sink = event_sink
    end

    def load_events(events)
      events.each do |event|
        handle_event(event.domain_event, event.metadata)
        @aggregate_sequence = event.aggregate_sequence
      end
    end

    def sink_event(domain_event, metadata)
      event_sink.sink build_staged_event(domain_event, metadata)
    end

    def stage_event(domain_event, metadata)
      staged_event = build_staged_event(domain_event, metadata)
      staged_events << staged_event

      handle_event(domain_event, metadata)
      @aggregate_sequence = staged_event.aggregate_sequence
    end

    def sink_staged_events
      event_sink.sink *staged_events
      staged_events.clear
    end

    private

    attr_reader :event_sink
    attr_reader :staged_events
    attr_reader :aggregate_sequence

    def build_staged_event(domain_event, metadata)
      StagedEvent.new(
        aggregate_id: id,
        aggregate_sequence: aggregate_sequence.next,
        domain_event: domain_event,
        metadata: metadata.to_h,
      )
    end

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
