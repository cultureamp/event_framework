module EventFramework
  module EventStore
    RSpec.describe SequenceStats do
      let(:database) { TestDomain.database(:event_store) }
      let(:event_type_resolver) { EventTypeResolver.new(event_context_module: TestDomain) }

      def insert_event(sequence:, aggregate_type:, event_type:)
        database[:events].overriding_system_value.insert(
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

      subject(:sequence_stats) { described_class.new(database: database, event_type_resolver: event_type_resolver) }

      describe '.max_sequence' do
        let(:event_classes) do
          [
            double(:event_class, name: 'A::A'),
            double(:event_class, name: 'A::B'),
          ]
        end

        it 'returns the max sequence for the aggregate and event type' do
          expect(sequence_stats.max_sequence(event_classes: event_classes)).to eq 3
        end

        context 'when no rows are returned' do
          let(:event_classes) do
            [
              double(:event_class, name: 'Z::Z'),
            ]
          end

          it 'returns 0' do
            expect(sequence_stats.max_sequence(event_classes: event_classes)).to eq 0
          end
        end
      end
    end
  end
end
