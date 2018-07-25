module EventFramework
  module EventStore
    class Source
      autoload :EventTypeDeserializer, 'event_store/source/event_type_deserializer'

      LIMIT = 1000
      EventBuilder = -> (row) {
        domain_event = EventTypeDeserializer.call(row[:type]).new(row[:body])

        Event.new(
          id: row[:id],
          sequence: row[:sequence],
          aggregate_id: row[:aggregate_id],
          aggregate_sequence: row[:aggregate_sequence],
          metadata: Event::Metadata.new(row[:metadata]),
          domain_event: domain_event,
        )
      }

      class << self
        def get_from(sequence)
          database[:events]
            .where(Sequel.lit('sequence >= ?', sequence))
            .order(:sequence)
            .limit(LIMIT)
            .map do |row|
              EventBuilder.call(row)
            end
        end

        def get_for_aggregate(aggregate_id)
          database[:events]
            .where(aggregate_id: aggregate_id)
            .order(:aggregate_sequence)
            .map do |row|
              EventBuilder.call(row)
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
