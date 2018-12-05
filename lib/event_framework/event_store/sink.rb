module EventFramework
  module EventStore
    class Sink
      ConcurrencyError = Class.new(RetriableException)

      AggregateIdMismatchError = Class.new(Error)

      class << self
        def sink(staged_events, database: EventStore.database)
          return if staged_events.empty?

          begin
            lock_result = try_lock(database)
            raise ConcurrencyError unless locked?(lock_result)
          rescue ConcurrencyError
            sleep 0.01
            retry
          end

          new_event_rows = sink_staged_events(staged_events, database)

          # NOTE: This is the "ugly" part of the framework that is only here to
          # support our current use-case where we need to update our MongoDB
          # synchronously.
          # binding.pry
          new_events = new_event_rows.map { |row| EventBuilder.call(row) }

          EventFramework.config.after_sink_hook.call(new_events)

          nil
        ensure
          unlock(database) if locked?(lock_result)
        end

        private

        def sink_staged_events(staged_events, database)
          new_event_rows = []

          database.transaction do
            staged_events.each do |staged_event|
              begin
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
          end

          new_event_rows
        end

        def try_lock(database)
          database.select(Sequel.function(:pg_try_advisory_lock, -1)).first
        end

        def unlock(database)
          database.select(Sequel.function(:pg_advisory_unlock, -1)).first[:pg_advisory_unlock]
        end

        def locked?(lock_result)
          lock_result && lock_result[:pg_try_advisory_lock]
        end
      end
    end
  end
end
