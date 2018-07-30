module EventFramework
  class CommandHandler
    attr_reader :repository

    def initialize(metadata:, repository: Repository.new)
      @repository = repository
      @metadata = metadata
    end

    private

    attr_reader :metadata

    def with_aggregate(aggregate_class, aggregate_id)
      aggregate = repository.load_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      repository.save_aggregate(aggregate)
    end

    # TODO: with_new_aggregate
  end
end
