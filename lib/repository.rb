module EventFramework
  class Repository
    def self.load_aggregate(aggregate_class, aggregate_id)
      events = EventStore::Source.get_for_aggregate(aggregate_id)

      aggregate_class.new(aggregate_id, EventStore::Sink).tap do |aggregate|
        aggregate.load_events(events)
      end
    end
  end
end
