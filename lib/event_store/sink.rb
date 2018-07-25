module EventFramework
  module EventStore
    class Sink
      ConcurrencyError = Class.new(Error)
      AggregateIdMismatch = Class.new(Error)
      EventBodySerializer = -> (event) {
        event.to_h.reject do |k, _v|
          %i[
            aggregate_id
            aggregate_sequence
            metadata
          ].include?(k)
        end
      }
      MetadataSerializer = -> (metadata) {
        ['created_at', Sequel.lit(%q{to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')})] +
          metadata.to_h.flat_map { |k, v| v && [k.to_s, v.to_s] }.compact
      }
      EventTypeSerializer = -> (event) {
        event.class.name.split('::').last
      }

      class << self
        def sink(aggregate_id:, events:, metadata:, expected_current_aggregate_sequence:)
          current_aggregate_sequence = expected_current_aggregate_sequence

          database.transaction do
            events.each do |event|
              begin
                database[:events].insert(
                  aggregate_id: aggregate_id,
                  aggregate_sequence: current_aggregate_sequence += 1,
                  type: EventTypeSerializer.call(event),
                  body: Sequel.pg_jsonb(EventBodySerializer.call(event)),
                  metadata: Sequel.function(:json_build_object, *MetadataSerializer.call(metadata)),
                )
              rescue Sequel::UniqueConstraintViolation
                raise ConcurrencyError,
                  "error saving aggregate_id #{aggregate_id.inspect}, aggregate_sequence mismatch"
              end
            end
          end
        end

        private

        def database
          EventStore.database
        end
      end
    end
  end
end
