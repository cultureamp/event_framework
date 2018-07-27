module EventFramework
  class CommandHandler
    attr_reader :repository

    def initialize(metadata:, repository: Repository)
      @repository = repository
      @metadata = metadata
    end

    private

    def with_aggregate(aggregate_class, aggregate_id)
      aggregate = repository.load_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      repository.save aggregate, metadata
    end

    attr_reader :metadata

    # TODO: with_new_aggregate
  end
end
