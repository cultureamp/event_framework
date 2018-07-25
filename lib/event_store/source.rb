module EventFramework
  module EventStore
    class Source
      autoload :EventBuilder, 'event_store/source/event_builder'

      LIMIT = 1000

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
