module EventFramework
  module EventStore
    class Sink
      AggregateIdMismatchError = Class.new(Error)
      ConcurrencyError = Class.new(RetriableException)

      MAX_RETRIES = 100

      def initialize(database: EventStore.database, logger: Logger.new(STDOUT))
        @database = database
        @logger = logger
      end

      def sink(staged_events)
        return if staged_events.empty?

        new_event_rows = sink_staged_events(staged_events, database)

        # NOTE: This is the "ugly" part of the framework that is only here to
        # support our current use-case where we need to update our MongoDB
        # synchronously.
        new_events = new_event_rows.map { |row| EventBuilder.call(row) }

        EventFramework.config.after_sink_hook.call(new_events)

        nil
      end

      private

      attr_reader :database, :logger

      def sink_staged_events(staged_events, database)
        new_event_rows = []

        database.transaction do
          get_lock_with_retry(correlation_id: staged_events.first.metadata.correlation_id)

          staged_events.each do |staged_event|
            new_event_rows += database[:events].returning.insert(
              aggregate_id: staged_event.aggregate_id,
              aggregate_sequence: staged_event.aggregate_sequence,
              aggregate_type: staged_event.aggregate_type,
              event_type: staged_event.event_type,
              body: Sequel.pg_jsonb(staged_event.body),
              metadata: Sequel.pg_jsonb(staged_event.metadata.to_h),
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
          raise ConcurrencyError, 'error obtaining lock' unless locked?(lock_result)
        rescue ConcurrencyError => e
          tries += 1
          if tries > MAX_RETRIES
            logger.info(msg: 'event_framework.event_store.sink.max_retries_reached', tries: tries, correlation_id: correlation_id)
            raise e
          end
          logger.info(msg: 'event_framework.event_store.sink.retry', tries: tries, correlation_id: correlation_id)
          sleep 0.1
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
