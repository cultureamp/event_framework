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
        lock_timeout_milliseconds: LOCK_TIMEOUT_MILLISECONDS,
        event_builder: EventBuilder.new(event_type_resolver: event_type_resolver)
      )
        @database = database
        @event_type_resolver = event_type_resolver
        @logger = logger
        @event_builder = event_builder
        @lock_timeout_milliseconds = lock_timeout_milliseconds
      end

      def transaction
        database.transaction { yield }
      end

      def sink(staged_events)
        return if staged_events.empty?

        new_event_rows = sink_staged_events(staged_events)

        # NOTE: This is the "ugly" part of the framework that is only here to
        # support our current use-case where we need to update our MongoDB
        # synchronously.
        new_events = new_event_rows.map { |row| event_builder.call(row) }

        EventFramework.config.after_sink_hook.call(new_events)

        nil
      end

      private

      attr_reader :database, :event_type_resolver, :logger, :event_builder, :lock_timeout_milliseconds

      def sink_staged_events(staged_events)
        aggregate_id = staged_events.map(&:aggregate_id).first

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

          new_event_rows = database.from(insert_events_function).select_all.to_a
        rescue Sequel::UniqueConstraintViolation
          raise StaleAggregateError, "error saving aggregate_id #{aggregate_id}, aggregate_sequence mismatch"
        rescue Sequel::DatabaseLockTimeout => e
          logger.info(
            msg: "event_framework.event_store.sink.lock_error",
            correlation_id: staged_events.first.metadata.correlation_id
          )
          raise UnableToGetLockError, "error obtaining lock"
        end

        new_event_rows
      end
    end
  end
end
