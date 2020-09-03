module EventFramework
  module EventStore
    class Sink
      AggregateIdMismatchError = Class.new(Error)
      ConcurrencyError = Class.new(RetriableException)

      LOCK_RETRY_COUNT = 100
      LOCK_RETRY_SLEEP = 0.1

      def initialize(
        database:, event_type_resolver:, logger: Logger.new(STDOUT),
        lock_retry_count: LOCK_RETRY_COUNT, lock_retry_sleep: LOCK_RETRY_SLEEP
      )
        @database = database
        @event_type_resolver = event_type_resolver
        @logger = logger
        @event_builder = EventBuilder.new(event_type_resolver: event_type_resolver)
        @lock_retry_count = lock_retry_count
        @lock_retry_sleep = lock_retry_sleep
      end

      def transaction
        database.transaction { yield }
      end

      def sink(staged_events)
        return if staged_events.empty?

        new_event_rows = sink_staged_events(staged_events, database)

        # NOTE: This is the "ugly" part of the framework that is only here to
        # support our current use-case where we need to update our MongoDB
        # synchronously.
        new_events = new_event_rows.map { |row| event_builder.call(row) }

        EventFramework.config.after_sink_hook.call(new_events)

        nil
      end

      private

      attr_reader :database, :event_type_resolver, :logger, :event_builder, :lock_retry_count, :lock_retry_sleep

      def sink_staged_events(staged_events, database)
        new_event_rows = []

        database.transaction do
          get_lock_with_retry(correlation_id: staged_events.first.metadata.correlation_id)

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

      def get_lock_with_retry(correlation_id:)
        tries = 0
        begin
          lock_result = try_lock(database)
          raise ConcurrencyError, "error obtaining lock" unless locked?(lock_result)
        rescue ConcurrencyError => e
          tries += 1
          if tries > lock_retry_count
            logger.info(msg: "event_framework.event_store.sink.max_retries_reached", tries: tries, correlation_id: correlation_id)
            raise e
          end
          logger.info(msg: "event_framework.event_store.sink.retry", tries: tries, correlation_id: correlation_id)
          sleep lock_retry_sleep
          retry
        end
      end

      def try_lock(database)
        database.select(Sequel.function(:pg_try_advisory_xact_lock, -1)).first
      end

      def locked?(lock_result)
        lock_result && lock_result[:pg_try_advisory_xact_lock]
      end
    end
  end
end
