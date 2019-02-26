module EventFramework
  module EventStore
    class SequenceStats
      class << self
        # def max_sequence(database: EventStore.database, event_classes: nil)
        def max_sequence(database: EventStore.database)
          scope = database[:events_sequence_stats]

          # if event_classes
          #   event_type_descriptions = event_classes.map { |event_type| EventTypeSerializer.call(event_type) }
          #   scope = scope.where(
          #     aggregate_type: event_type_descriptions.map(&:aggregate_type),
          #     event_type: event_type_descriptions.map(&:event_type),
          #   )
          # end

          scope.max(:max_sequence).to_i
        end
      end
    end
  end
end
