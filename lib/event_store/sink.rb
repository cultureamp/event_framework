require 'database'
require 'securerandom'

module EventFramework
  class EventStore
    class Sink
      ConcurrencyError = Class.new(Error)
      EventBodySerializer = -> (event) {
        event.to_h.reject do |k, v|
          %i[
            aggregate_id
            aggregate_sequence_id
          ].include?(k)
        end
      }

      def self.sink(aggregate_id:, events:)
        database.transaction do
          events.each do |event|
            begin
              database[:events].insert(
                aggregate_id: aggregate_id,
                aggregate_sequence_id: event.aggregate_sequence_id,
                type: event.class.name,
                body: Sequel.pg_jsonb(EventBodySerializer.call(event))
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
