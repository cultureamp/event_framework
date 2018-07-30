module EventFramework
  class Repository
    def initialize(sink: EventStore::Sink, source: EventStore::Source)
      @sink = sink
      @source = source
    end

    def load_aggregate(aggregate_class, aggregate_id)
      events = @source.get_for_aggregate(aggregate_id)

      aggregate_class.new(aggregate_id).tap do |aggregate|
        aggregate.load_events(events)
      end
    end

    def self.save_aggregate(aggregate)
      @sink.sink(aggregate.staged_events)
    end
  end
end
