module EventFramework
  class Reactor < EventProcessor
    CONCURRENCY_RETRY_THRESHOLD = 3

    def initialize(repository:, error_reporter: EventFramework.config.event_processor_error_reporter)
      @repository = repository
      @error_reporter = error_reporter
    end

    extend Forwardable

    def handle_event(event)
      self._current_event = event

      super
    ensure
      self._current_event = nil
    end

    private

    attr_accessor :_current_event
    attr_reader :repository

    def with_aggregate(aggregate_class, aggregate_id, metadata:)
      execution_attempts ||= CONCURRENCY_RETRY_THRESHOLD
      aggregate = repository.load_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      metadata.causation_id ||= _current_event.id

      repository.save_aggregate(aggregate, metadata: metadata)
    rescue EventStore::Sink::ConcurrencyError
      if execution_attempts.zero?
        raise
      else
        execution_attempts -= 1
        retry
      end
    end

    def with_new_aggregate(aggregate_class, aggregate_id, metadata:)
      aggregate = repository.new_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      metadata.causation_id ||= _current_event.id

      repository.save_aggregate(aggregate, metadata: metadata, ensure_new_aggregate: true)
    end
  end
end
