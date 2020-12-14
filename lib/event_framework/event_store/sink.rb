module EventFramework
  module EventStore
    class Sink
      AggregateIdMismatchError = Class.new(Error)
      UnableToGetLockError = Class.new(Error)
      MultipleAggregateIDsError = Class.new(Error)
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
        aggregate_id = begin
          ids = staged_events.map(&:aggregate_id)
          raise MultipleAggregateIDsError if ids.uniq.count != 1
          ids.first
        end

        serialized_events = staged_events.map do |staged_event|
          serialized_event_type = event_type_resolver.serialize(staged_event.domain_event.class)

          # The order of this array matches the arguments
          # for the Postgresql insert_events function.
          [
            Sequel.cast(serialized_event_type.event_type, "text"),
            Sequel.cast(serialized_event_type.aggregate_type, "text"),
            staged_event.aggregate_sequence,
            Sequel.pg_jsonb(staged_event.body),
            Sequel.pg_jsonb(staged_event.metadata.to_h)
          ]
        end

        # Transpose the serialized events into arrays of the same types.
        #
        #   [
        #     ["MyEventType1", "MyAggregateType1", ...],
        #     ["MyEventType2", "MyAggregateType2", ...]
        #   ]
        #
        # =>
        #
        #   [
        #     ["MyEventType1", "MyEventType2"],
        #     ["MyAggregateType1", "MyAggregateType2"],
        #     ...
        #   ]
        #
        function_args = serialized_events
          .transpose
          .map { |a| Sequel.pg_array(a) }

        begin
          insert_events_function = Sequel.function(
            :insert_events,
            Sequel.cast(aggregate_id, "uuid"),
            *function_args,
            lock_timeout_milliseconds
          )

          new_event_rows = database.from(insert_events_function).select_all.to_a
        rescue Sequel::UniqueConstraintViolation => e
          if e.message.include?("events_aggregate_id_aggregate_sequence_index")
            logger.info(
              msg: "event_framework.event_store.sink.stale_aggregate_error",
              correlation_id: staged_events.first.metadata.correlation_id
            )
            raise StaleAggregateError, "error saving aggregate_id #{aggregate_id}, aggregate_sequence mismatch"
          else
            raise e
          end
        rescue Sequel::DatabaseLockTimeout => e
          logger.info(
            msg: "event_framework.event_store.sink.unable_to_get_lock_error",
            correlation_id: staged_events.first.metadata.correlation_id
          )
          raise UnableToGetLockError, "error obtaining lock"
        end

        new_event_rows
      end
    end
  end
end
