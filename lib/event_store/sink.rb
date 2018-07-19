require 'database'
require 'securerandom'

module EventFramework
  class EventStore
    class Sink
      ConcurrencyError = Class.new(Error)

      def self.sink(aggregate_id:, events:)
        database.transaction do
          events.each do |event|
            body = event.to_h.tap do |h|
              h.delete :aggregate_id
              h.delete :aggregate_sequence_id
            end

            begin
              database[:events].insert(
                aggregate_id: aggregate_id,
                aggregate_sequence_id: event.aggregate_sequence_id,
                type: event.class.name,
                body: Sequel.pg_jsonb(body)
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
