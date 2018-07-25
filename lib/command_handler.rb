module EventFramework
  class CommandHandler
    attr_reader :repository

    attr_reader :event_metadata

    def initialize(user_id:, account_id:, repository: Repository)
      @repository = repository

      @event_metadata = Metadata.new(
        user_id: user_id,
        account_id: account_id,
      )
    end

    def with_aggregate(aggregate_class, aggregate_id)
      aggregate = repository.load_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      repository.save aggregate, @event_metadata
    end

    # TODO: with_new_aggregate
  end
end
