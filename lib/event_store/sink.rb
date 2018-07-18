require 'database'
require 'securerandom'

module EventFramework
  class EventStore
    class Sink
      def self.sink(event)
        EventStore.database[:events].insert(
          aggregate_id: event.aggregate_id,
          type: event.class.name,
          body: Sequel.pg_jsonb(event.to_h.tap { |h| h.delete :aggregate_id })
        )
      end
    end
  end
end
