module EventFramework
  module EventStore
    RSpec.describe SequenceStats do
      def insert_event(sequence:, aggregate_type:, event_type:)
        EventStore.database[:events].overriding_system_value.insert(
          sequence: sequence,
          aggregate_id: SecureRandom.uuid,
          aggregate_sequence: 1,
          aggregate_type: aggregate_type,
          event_type: event_type,
          body: Sequel.pg_jsonb({}),
          metadata: Sequel.pg_jsonb({}),
        )
      end

      describe '.all' do
        it 'the max sequence grouped by aggregate and event type' do
          insert_event sequence: 1, aggregate_type: 'A', event_type: 'A'
          insert_event sequence: 2, aggregate_type: 'A', event_type: 'A'
          insert_event sequence: 3, aggregate_type: 'A', event_type: 'B'
          insert_event sequence: 4, aggregate_type: 'B', event_type: 'A'
          insert_event sequence: 5, aggregate_type: 'B', event_type: 'A'
          insert_event sequence: 6, aggregate_type: 'B', event_type: 'C'

          described_class.refresh

          expect(described_class.all).to match_array [
            { aggregate_type: 'A', event_type: 'A', max_sequence: 2 },
            { aggregate_type: 'A', event_type: 'B', max_sequence: 3 },
            { aggregate_type: 'B', event_type: 'A', max_sequence: 5 },
            { aggregate_type: 'B', event_type: 'C', max_sequence: 6 },
          ]
        end
      end
    end
  end
end
