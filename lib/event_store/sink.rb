module EventFramework
  module EventStore
    class Sink
      ConcurrencyError = Class.new(Error)
      AggregateIdMismatchError = Class.new(Error)

      MetadataSerializer = -> (metadata) {
        ['created_at', Sequel.lit(%q{to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')})] +
          metadata.to_h.flat_map { |k, v| v && [k.to_s, v.to_s] }.compact
      }

      class << self
        def sink(events)
          return if events.empty?

          new_event_rows = []

          database.transaction do
            events.each do |staged_event|
              begin
                new_event_rows += database[:events].returning.insert(
                  aggregate_id: staged_event.aggregate_id,
                  aggregate_sequence: staged_event.aggregate_sequence,
                  type: staged_event.type,
                  body: Sequel.pg_jsonb(staged_event.body),
                  metadata: Sequel.function(:json_build_object, *MetadataSerializer.call(staged_event.metadata)),
                )
              rescue Sequel::UniqueConstraintViolation
                raise ConcurrencyError,
                      "error saving aggregate_id #{staged_event.aggregate_id.inspect}, aggregate_sequence mismatch"
              end
            end
          end

          # NOTE: This is the "ugly" part of the framework that is only here to
          # support our current use-case where we need to update our MongoDB
          # synchronously.
          new_events = new_event_rows.map do |row|
            # TODO: Move EventBuilder to EventStore::EventBuilder
            EventStore::Source::EventBuilder.call(row)
          end
          EventFramework.config.after_sink_hook.call(new_events)

          nil
        end

        private

        def database
          EventStore.database
        end
      end
    end
  end
end
