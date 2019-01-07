module EventFramework
  module EventStore
    RSpec.describe SequenceStats do
      def insert_event(sequence:, aggregate_type:, event_type:)
        EventFramework.test_database[:events].overriding_system_value.insert(
          sequence: sequence,
          aggregate_id: SecureRandom.uuid,
          aggregate_sequence: 1,
          aggregate_type: aggregate_type,
          event_type: event_type,
          body: Sequel.pg_jsonb({}),
          metadata: Sequel.pg_jsonb({}),
        )
      end

      before do
        insert_event sequence: 1, aggregate_type: 'A', event_type: 'A'
        insert_event sequence: 2, aggregate_type: 'A', event_type: 'A'
        insert_event sequence: 3, aggregate_type: 'A', event_type: 'B'
        insert_event sequence: 4, aggregate_type: 'B', event_type: 'A'
        insert_event sequence: 5, aggregate_type: 'B', event_type: 'A'
        insert_event sequence: 6, aggregate_type: 'B', event_type: 'C'
      end

      subject(:sequence_stats) { described_class.new(database: EventFramework.test_database) }

      describe '.max_sequence' do
        it 'returns the max sequence in the event store' do
          expect(sequence_stats.max_sequence).to eq 6
        end
      end
    end
  end
end
