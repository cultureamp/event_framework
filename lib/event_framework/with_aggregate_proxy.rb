module EventFramework
  class WithAggregateProxy
    def initialize(repository, metadata)
      @repository = repository
      @metadata = metadata
    end

    def with_aggregate(aggregate_class, aggregate_id, metadata: @metadata)
      aggregate = repository.load_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      repository.save_aggregate(aggregate, metadata: metadata)
    end

    def with_new_aggregate(aggregate_class, aggregate_id, metadata: @metadata)
      aggregate = repository.new_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      repository.save_aggregate(aggregate, metadata: metadata, ensure_new_aggregate: true)
    end

    private

    attr_reader :repository
  end
end
