module EventFramework
  class CommandHandler
    AFTER_SINK = -> (events) { }

    attr_reader :repository

    def initialize(metadata:, repository: Repository)
      @repository = repository
      @metadata = metadata
    end

    private

    attr_reader :metadata

    def with_aggregate(aggregate_class, aggregate_id, after_sink: AFTER_SINK)
      aggregate = repository.load_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      sunk_events = repository.save_aggregate(aggregate)

      after_sink.call(sunk_events)
    end

    # TODO: with_new_aggregate
  end
end
