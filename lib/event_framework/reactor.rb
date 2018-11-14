module EventFramework
  class Reactor < EventProcessor
    def initialize(repository = Repository.new)
      @repository = repository
    end

    extend Forwardable

    def handle_event(event)
      self._current_event = event

      self.class.event_handlers.for(event.domain_event.type).each do |handler|
        instance_exec(event.aggregate_id, event.domain_event, event.metadata, event.id, &handler)
      end
    ensure
      self._current_event = nil
    end

    private

    attr_accessor :_current_event
    attr_reader :repository

    def with_aggregate(aggregate_class, aggregate_id, metadata:)
      aggregate = repository.load_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      metadata.causation_id ||= _current_event.id

      repository.save_aggregate(aggregate, metadata: metadata)
    end

    def with_new_aggregate(aggregate_class, aggregate_id, metadata:)
      aggregate = repository.new_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      metadata.causation_id ||= _current_event.id

      repository.save_aggregate(aggregate, metadata: metadata, ensure_new_aggregate: true)
    end
  end
end
