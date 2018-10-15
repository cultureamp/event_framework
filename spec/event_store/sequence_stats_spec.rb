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

      before do
        insert_event sequence: 1, aggregate_type: 'A', event_type: 'A'
        insert_event sequence: 2, aggregate_type: 'A', event_type: 'A'
        insert_event sequence: 3, aggregate_type: 'A', event_type: 'B'
        insert_event sequence: 4, aggregate_type: 'B', event_type: 'A'
        insert_event sequence: 5, aggregate_type: 'B', event_type: 'A'
        insert_event sequence: 6, aggregate_type: 'B', event_type: 'C'

        described_class.refresh
      end

      describe '.max_sequence' do
        let(:event_classes) do
          [
            double(:event_class, to_s: 'A::A'),
            double(:event_class, to_s: 'A::B'),
          ]
        end

        it 'the max sequence grouped by aggregate and event type' do
          expect(described_class.max_sequence(event_classes: event_classes)).to eq 3
        end

        context 'when no rows are returned' do
          let(:event_classes) do
            [
              double(:event_class, to_s: 'Z::Z'),
            ]
          end

          it 'returns 0' do
            expect(described_class.max_sequence(event_classes: event_classes)).to eq 0
          end
        end
      end
    end
  end
end
