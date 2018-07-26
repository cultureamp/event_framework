module EventFramework
  class Repository
    def self.load_aggregate(aggregate_class, aggregate_id)
      events = EventStore::Source.get_for_aggregate(aggregate_id)
      aggregate_class.load_from_history(aggregate_id, events)
    end

    def self.save(aggregate, metadata)
      if aggregate.new_events.any?
        EventStore::Sink.sink(
          aggregate_id: aggregate.id,
          domain_events: aggregate.new_events,
          expected_aggregate_sequence: aggregate.aggregate_sequence,
          metadata: metadata,
        )
      end
    end
  end
end
