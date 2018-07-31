module EventFramework
  class Repository
    def self.load_aggregate(aggregate_class, aggregate_id)
      events = EventStore::Source.get_for_aggregate(aggregate_id)

      aggregate_class.new(aggregate_id).tap do |aggregate|
        aggregate.load_events(events)
      end
    end

    def self.save_aggregate(aggregate)
      EventStore::Sink.sink(aggregate.staged_events)
    end
  end
end
