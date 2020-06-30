module EventFramework
  module EventStore
    class Source
      LIMIT = 1000

      def initialize(database:, event_type_resolver:, logger: Logger.new(STDOUT))
        @database = database
        @event_type_resolver = event_type_resolver
        @logger = logger
        @event_builder = EventBuilder.new(event_type_resolver: event_type_resolver)
      end

      def get_after(sequence, event_classes: nil)
        scope = database[:events].where(Sequel.lit("sequence > ?", sequence))
        scope = scope_to_event_classes(scope, event_classes: event_classes) if event_classes

        scope
          .where(Sequel.lit("sequence > ?", sequence))
          .order(:sequence)
          .limit(LIMIT)
          .map { |row| event_builder.call(row) }
      end

      def get_for_aggregate(aggregate_id)
        database[:events]
          .where(aggregate_id: aggregate_id)
          .order(:aggregate_sequence)
          .map { |row| event_builder.call(row) }
      end

      private

      attr_reader :database, :event_type_resolver, :logger, :event_builder

      def scope_to_event_classes(scope, event_classes:)
        event_type_descriptions = event_classes.map { |event_type| event_type_resolver.serialize(event_type) }

        scope.where(
          aggregate_type: event_type_descriptions.map(&:aggregate_type),
          event_type: event_type_descriptions.map(&:event_type)
        )
      end
    end
  end
end
