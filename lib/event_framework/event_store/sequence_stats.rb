module EventFramework
  module EventStore
    class SequenceStats
      class << self
        def all(database: EventStore.database)
          database[:events_sequence_stats].all
        end

        def max_sequence(database: EventStore.database, event_classes:)
          event_type_descriptions = event_classes.map { |event_type| EventTypeSerializer.call(event_type) }

          scope = database[:events_sequence_stats]
          scope = scope.where(
            aggregate_type: event_type_descriptions.map(&:aggregate_type),
            event_type: event_type_descriptions.map(&:event_type),
          )
          scope.max(:max_sequence).to_i
        end

        def refresh(database: EventStore.database)
          database.refresh_view(:events_sequence_stats)
        end
      end
    end
  end
end
