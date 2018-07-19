require 'database'
require 'securerandom'

module EventFramework
  class EventStore
    class Sink
      def self.sink(aggregate_id:, events:)
        events.each do |event|
          database[:events].insert(
            aggregate_id: aggregate_id,
            type: event.class.name,
            body: Sequel.pg_jsonb(event.to_h.tap { |h| h.delete :aggregate_id })
          )
        end
      end

      private_class_method \
      def self.database
        EventStore.database
      end
    end
  end
end
