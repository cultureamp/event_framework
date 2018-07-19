require 'database'
require 'securerandom'

module EventFramework
  class EventStore
    class Sink
      ConcurrencyError = Class.new(Error)

      def self.sink(aggregate_id:, events:, expected_max_sequence_id:)
        # TODO: Lock table instead of a transaction, the transaction won't save
        # us here.
        database.transaction do
          actual_max_sequence_id = database[:events].where(aggregate_id: aggregate_id).max(:sequence_id)

          if expected_max_sequence_id != actual_max_sequence_id
            raise ConcurrencyError, "expected max sequence_id #{expected_max_sequence_id.inspect}, was #{actual_max_sequence_id.inspect}"
          end

          events.each do |event|
            database[:events].insert(
              aggregate_id: aggregate_id,
              type: event.class.name,
              body: Sequel.pg_jsonb(event.to_h.tap { |h| h.delete :aggregate_id })
            )
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
