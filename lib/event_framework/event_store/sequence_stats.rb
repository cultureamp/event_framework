module EventFramework
  module EventStore
    class SequenceStats
      def initialize(database:, event_type_resolver:)
        @database = database
        @event_type_resolver = event_type_resolver
      end

      attr_reader :database, :event_type_resolver

      def max_sequence(event_classes: nil)
        scope = database[:events_sequence_stats]

        if event_classes
          event_type_descriptions = event_classes.map { |event_type| event_type_resolver.serialize(event_type) }

          scope = scope.where(
            aggregate_type: event_type_descriptions.map(&:aggregate_type),
            event_type: event_type_descriptions.map(&:event_type)
          )
        end

        scope.max(:max_sequence).to_i
      end
    end
  end
end
