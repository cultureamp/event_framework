module EventFramework
  module EventStore
    class Sink
      AggregateIdMismatchError = Class.new(Error)
      ConcurrencyError = Class.new(RetriableException)

      # 10 seconds
      LOCK_TIMEOUT_MILLISECONDS = 10_000

      def initialize(
        database:, event_type_resolver:,
        logger: Logger.new(STDOUT),
        lock_timeout_milliseconds: LOCK_TIMEOUT_MILLISECONDS
      )
        @database = database
        @event_type_resolver = event_type_resolver
        @logger = logger
        @event_builder = EventBuilder.new(event_type_resolver: event_type_resolver)
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
        new_event_rows = []

        with_lock(correlation_id: staged_events.first.metadata.correlation_id) do
          staged_events.each do |staged_event|
            serialized_event_type = event_type_resolver.serialize(staged_event.domain_event.class)

            new_event_rows += database[:events].returning.insert(
              aggregate_id: staged_event.aggregate_id,
              aggregate_sequence: staged_event.aggregate_sequence,
              aggregate_type: serialized_event_type.aggregate_type,
              event_type: serialized_event_type.event_type,
              body: Sequel.pg_jsonb(staged_event.body),
              metadata: Sequel.pg_jsonb(staged_event.metadata.to_h)
            )
          rescue Sequel::UniqueConstraintViolation
            raise ConcurrencyError,
              "error saving aggregate_id #{staged_event.aggregate_id.inspect}, aggregate_sequence mismatch"
          end
        end

        new_event_rows
      end

      # Set a local lock_timeout within a transaction then get an exclusive
      # advisory lock so that we're the only database connection that can sink
      # an event.
      #
      # If you're modifing the locking logic you can test that it's working
      # correctly using the ./bin/demonstrate_event_sequence_id_gaps script.
      def with_lock(correlation_id:)
        database.transaction do
          database.execute("SET LOCAL lock_timeout = '#{lock_timeout_milliseconds}ms'; SELECT pg_advisory_xact_lock(-1)")
          yield
        end
      rescue Sequel::DatabaseLockTimeout => e
        logger.info(msg: "event_framework.event_store.sink.lock_error", correlation_id: correlation_id)
        raise ConcurrencyError, "error obtaining lock"
      end
    end
  end
end
