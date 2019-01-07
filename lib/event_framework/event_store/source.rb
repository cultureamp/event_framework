module EventFramework
  module EventStore
    class Source
      LIMIT = 1000

      def initialize(database:, logger: Logger.new(STDOUT))
        @database = database
        @logger = logger
      end

      def get_after(sequence)
        database[:events]
          .where(Sequel.lit('sequence > ?', sequence))
          .order(:sequence)
          .limit(LIMIT)
          .map { |row| EventBuilder.call(row) }
      end

      def get_for_aggregate(aggregate_id)
        database[:events]
          .where(aggregate_id: aggregate_id)
          .order(:aggregate_sequence)
          .map { |row| EventBuilder.call(row) }
      end

      private

      attr_reader :database, :logger
    end
  end
end
