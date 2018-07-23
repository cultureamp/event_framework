module EventFramework
  module EventStore
    class Source
      LIMIT = 1000
      EventBuilder = -> (row) {
        klass = EventTypeDeserializer.call(row[:type])
        klass.new(
          row[:body].merge(
            aggregate_id: row[:aggregate_id],
            aggregate_sequence: row[:aggregate_sequence],
            metadata: Event::Metadata.new(row[:metadata]),
          ),
        )
      }
      EventTypeDeserializer = -> (event_type) {
        EventFramework.config.event_namespace_class.const_get(event_type)
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
