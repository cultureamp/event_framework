module EventFramework
  module EventStore
    class Source
      LIMIT = 1000

      def initialize(database:, logger: Logger.new(STDOUT))
        @database = database
        @logger = logger
      end

      def get_after(sequence, event_classes: nil)
        scope = database[:events].where(Sequel.lit('sequence > ?', sequence))
        scope = scope_to_event_classes(scope, event_classes: event_classes) if event_classes

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

      attr_reader :database, :logger

      def scope_to_event_classes(scope, event_classes:)
        event_type_descriptions = event_classes.map { |event_type| EventTypeSerializer.call(event_type) }

        scope.where(
          aggregate_type: event_type_descriptions.map(&:aggregate_type),
          event_type: event_type_descriptions.map(&:event_type),
        )
      end
    end
  end
end
