module EventFramework
  class Repository
    AggregateNotFound = Class.new(Error)
    AggregateAlreadyExists = Class.new(Error)

    def initialize(sink:, source:)
      @sink = sink
      @source = source
    end

    def new_aggregate(aggregate_class, aggregate_id)
      events = source.get_for_aggregate(aggregate_id)

      raise AggregateAlreadyExists, aggregate_id if events.count > 0

      aggregate_class.build(aggregate_id)
    end

    def load_aggregate(aggregate_class, aggregate_id)
      events = source.get_for_aggregate(aggregate_id)

      raise AggregateNotFound, aggregate_id if events.count == 0

      aggregate_class.build(aggregate_id).tap do |aggregate|
        aggregate.load_events(events)
      end
    end

    def new_or_existing_aggregate(aggregate_class, aggregate_id)
      events = source.get_for_aggregate(aggregate_id)

      aggregate_class.build(aggregate_id).tap do |aggregate|
        aggregate.load_events(events)
      end
    end

    def save_aggregate(aggregate, metadata:, ensure_new_aggregate: false)
      events = aggregate.staged_events.each_with_index.map do |staged_event, i|
        staged_event = staged_event.new(mutable_metadata: metadata)
        staged_event = staged_event.new(aggregate_sequence: i + 1) if ensure_new_aggregate
        staged_event
      end

      sink.sink(events)
    end

    private

    attr_reader :sink, :source
  end
end
