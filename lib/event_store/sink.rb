require 'database'

module EventFramework
  class EventStore
    class Sink
      ConcurrencyError = Class.new(Error)
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
        ['created_at', Sequel.lit("now() at time zone 'utc'")] + metadata.to_a.flatten.map(&:to_s)
      }

      def self.sink(aggregate_id:, events:)
        database.transaction do
          events.each do |event|
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

      private_class_method \
      def self.database
        EventStore.database
      end
    end
  end
end
