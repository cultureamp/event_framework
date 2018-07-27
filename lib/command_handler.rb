module EventFramework
  class CommandHandler
    attr_reader :repository

    def initialize(metadata:, repository: Repository)
      @repository = repository
      @metadata = metadata
    end

    private

    attr_reader :metadata

    def with_aggregate(aggregate_class, aggregate_id)
      aggregate = repository.load_aggregate(aggregate_class, aggregate_id)

      yield aggregate
    end

    # TODO: with_new_aggregate
  end
end
