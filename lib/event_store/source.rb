module EventFramework
  module EventStore
    class Source
      LIMIT = 1000

      class << self
        def get_after(sequence, event_classes: nil)
          scope = database[:events].where(Sequel.lit('sequence > ?', sequence))

          if event_classes
            event_type_descriptions = event_classes.map { |event_type| EventTypeSerializer.call(event_type) }

            scope = scope.where(
              aggregate_type: event_type_descriptions.map(&:aggregate_type),
              event_type: event_type_descriptions.map(&:event_type),
            )
          end

          scope.order(:sequence).limit(LIMIT).map do |row|
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
