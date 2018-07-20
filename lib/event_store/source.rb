require_relative '../database'

module EventFramework
  class EventStore
    class Source
      EventBuilder = -> (row) {
        klass = const_get(row[:type])
        klass.new(
          row[:body].merge(
            aggregate_id: row[:aggregate_id],
            aggregate_sequence_id: row[:aggregate_sequence_id],
            metadata: row[:metadata]
          )
        )
      }

      class << self
        def get(sequence_id)
          database[:events]
            .where(Sequel.lit('sequence_id >= ?', sequence_id))
            .order(:sequence_id)
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
