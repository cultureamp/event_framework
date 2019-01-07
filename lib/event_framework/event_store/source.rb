module EventFramework
  module EventStore
    class Source
      LIMIT = 1000

      def initialize(database:, event_type_deserializer:, logger: Logger.new(STDOUT))
        @database = database
        @logger = logger
        @event_builder = EventBuilder.new(event_type_deserializer: event_type_deserializer)
      end

      def get_after(sequence)
        database[:events]
          .where(Sequel.lit('sequence > ?', sequence))
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

      attr_reader :database, :logger, :event_builder
    end
  end
end
