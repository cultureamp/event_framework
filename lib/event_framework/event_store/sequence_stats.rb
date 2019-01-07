module EventFramework
  module EventStore
    class SequenceStats
      def initialize(database:)
        @database = database
      end

      def max_sequence
        database[:events_sequence_stats].max(:max_sequence).to_i
      end

      private

      attr_reader :database
    end
  end
end
