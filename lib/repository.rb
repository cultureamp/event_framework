module EventFramework
  class Repository
    def initialize(sink: EventStore::Sink, source: EventStore::Source)
      @sink = sink
      @source = source
    end

    def load_aggregate(aggregate_class, aggregate_id)
      events = @source.get_for_aggregate(aggregate_id)

      aggregate_class.build(aggregate_id).tap do |aggregate|
        aggregate.load_events(events)
      end
    end

    def save_aggregate(aggregate, metadata:, ensure_new_aggregate: false)
      events = aggregate.staged_events.each_with_index.map do |staged_event, i|
        staged_event = staged_event.new(metadata: metadata)
        staged_event = staged_event.new(aggregate_sequence: i + 1) if ensure_new_aggregate
        staged_event
      end

      @sink.sink(events)
    end
  end
end
