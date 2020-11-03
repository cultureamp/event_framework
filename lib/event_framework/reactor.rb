require "forwardable"

module EventFramework
  class Reactor < EventProcessor
    CONCURRENCY_RETRY_THRESHOLD = 3

    class << self
      # Public: Returns a new sub-class of Reactor with an overloaded
      # constructor that automatically injects required dependencies from
      # the given context_module
      #
      # This is a handy bit of syntactic magic which allows
      #
      # context_module - A Module that has been prepared as a context using
      #                  BoundedContext.initialize_bounded_context and
      #                  BoundedContext.build_command_dependency_chain!
      def [](context_module)
        Class.new(self).tap do |subclass|
          context_repository = context_module.container.resolve("repository")
          default_error_reporter = EventFramework.config.event_processor_error_reporter

          subclass.define_singleton_method(:new) do |repository: context_repository, error_reporter: default_error_reporter|
            allocate.tap do |instance|
              instance.send(:initialize, repository: repository, error_reporter: error_reporter)
            end
          end
        end
      end
    end

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

      metadata = metadata.new(causation_id: metadata.causation_id || _current_event.id)

      repository.save_aggregate(aggregate, metadata: metadata)
    rescue EventStore::Sink::UnableToGetLockError, EventStore::Sink::StaleAggregateError
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

      metadata = metadata.new(causation_id: metadata.causation_id || _current_event.id)

      repository.save_aggregate(aggregate, metadata: metadata, ensure_new_aggregate: true)
    end
  end
end
