module EventFramework
  module EventStore
    class Sink
      AggregateIdMismatchError = Class.new(Error)
      UnableToGetLockError = Class.new(Error)
      StaleAggregateError = Class.new(RetriableException)

      # 10 seconds
      LOCK_TIMEOUT_MILLISECONDS = 10_000

      def initialize(
        database:, event_type_resolver:,
        logger: Logger.new(STDOUT),
        tracer: EventFramework::Tracer::NullTracer.new,
        lock_timeout_milliseconds: LOCK_TIMEOUT_MILLISECONDS
      )
        @database = database
        @event_type_resolver = event_type_resolver
        @logger = logger
        # @tracer = tracer
        @tracer = Datadog.tracer # Hard-coding this to see if it gives us what we want
        @event_builder = EventBuilder.new(event_type_resolver: event_type_resolver)
        @lock_timeout_milliseconds = lock_timeout_milliseconds
      end

      def transaction
        database.transaction { yield }
      end

      def sink(staged_events)
        Datadog.tracer.trace("event_store.sink") do
          return if staged_events.empty?

          new_event_rows = []
          Datadog.tracer.trace("event_store.sink.sink_staged_events") do
            new_event_rows = sink_staged_events(staged_events)
          end

          # NOTE: This is the "ugly" part of the framework that is only here to
          # support our current use-case where we need to update our MongoDB
          # synchronously.
          new_events = []
          Datadog.tracer.trace("event_store.sink.build_events") do
            new_events = new_event_rows.map { |row| event_builder.call(row) }
          end

          Datadog.tracer.trace("event_store.sink.after_sink_hook") do
            EventFramework.config.after_sink_hook.call(new_events)
          end

          nil
        end
      end

      private

      attr_reader :database, :event_type_resolver, :logger, :tracer, :event_builder, :lock_timeout_milliseconds

      def sink_staged_events(staged_events)
        aggregate_id = begin
          ids = staged_events.map(&:aggregate_id)
          raise "multiple aggregate IDs" if ids.uniq.count != 1
          ids.first
        end

        serialized_events = nil
        Datadog.tracer.trace("event_store.sink.sink_staged_events.serialize_events") do
          serialized_events = staged_events.map do |staged_event|
            serialized_event_type = event_type_resolver.serialize(staged_event.domain_event.class)
            {
              aggregate_sequence: staged_event.aggregate_sequence,
              aggregate_type: serialized_event_type.aggregate_type,
              event_type: serialized_event_type.event_type,
              body: Sequel.pg_jsonb(staged_event.body),
              metadata: Sequel.pg_jsonb(staged_event.metadata.to_h)
            }
          end
        end

        new_event_rows = nil
        Datadog.tracer.trace("event_store.sink.sink_staged_events.insert_events") do
          begin
            insert_events_function = Sequel.function(
              :insert_events,
              Sequel.cast(aggregate_id, "uuid"),
              Sequel.pg_array(serialized_events.map { |e| Sequel.cast(e[:event_type], "text") }),
              Sequel.pg_array(serialized_events.map { |e| Sequel.cast(e[:aggregate_type], "text") }),
              Sequel.pg_array(serialized_events.map { |e| e[:aggregate_sequence] }),
              Sequel.pg_array(serialized_events.map { |e| e[:body] }),
              Sequel.pg_array(serialized_events.map { |e| e[:metadata] }),
              lock_timeout_milliseconds
            )

            Datadog.tracer.trace("event_store.sink.sink_staged_events.insert_events.invoke_function") do
              new_event_rows = database.from(insert_events_function).select_all.to_a
            end
          rescue Sequel::UniqueConstraintViolation
            logger.info(
              msg: "event_framework.event_store.sink.stale_aggregate_error",
              correlation_id: staged_events.first.metadata.correlation_id
            )
            raise StaleAggregateError, "error saving aggregate_id #{aggregate_id}, aggregate_sequence mismatch"
          rescue Sequel::DatabaseLockTimeout => e
            logger.info(
              msg: "event_framework.event_store.sink.unable_to_get_lock_error",
              correlation_id: staged_events.first.metadata.correlation_id
            )
            raise UnableToGetLockError, "error obtaining lock"
          end
        end

        new_event_rows
      end
    end
  end
end
