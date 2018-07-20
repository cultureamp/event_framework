module EventFramework
  module EventStore
    class Sink
      ConcurrencyError = Class.new(Error)
      AggregateIdMismatch = Class.new(Error)
      EventBodySerializer = -> (event) {
        event.to_h.reject do |k, _v|
          %i[
            aggregate_id
            aggregate_sequence_id
            metadata
          ].include?(k)
        end
      }
      MetadataSerializer = -> (metadata) {
        ['created_at', Sequel.lit("now() at time zone 'utc'")] +
          metadata.flat_map { |k, v| [k.to_s, v.to_s] }
      }

      class << self
        def sink(aggregate_id:, events:)
          database.transaction do
            events.each do |event|
              unless event.aggregate_id == aggregate_id
                raise AggregateIdMismatch,
                  "error saving event for #{event.aggregate_id.inspect} to #{aggregate_id.inspect}"
              end

              begin
                database[:events].insert(
                  aggregate_id: aggregate_id,
                  aggregate_sequence_id: event.aggregate_sequence_id,
                  type: event.class.name,
                  body: Sequel.pg_jsonb(EventBodySerializer.call(event)),
                  metadata: Sequel.function(:json_build_object, *MetadataSerializer.call(event.metadata)),
                )
              rescue Sequel::UniqueConstraintViolation
                raise ConcurrencyError,
                  "error saving aggregate_id #{aggregate_id.inspect}, aggregate_sequence_id mismatch"
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
