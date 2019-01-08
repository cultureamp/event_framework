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

        stub_const('TestDomain::A::A', Class.new)
        stub_const('TestDomain::A::B', Class.new)
        stub_const('TestDomain::B::A', Class.new)
        stub_const('TestDomain::A::C', Class.new)
      end

      let(:event_type_resolver) { EventTypeResolver.new(event_context_module: TestDomain) }

      subject(:sequence_stats) do
        described_class.new(
          database: EventFramework.test_database,
          event_type_resolver: event_type_resolver,
        )
      end

      describe '.max_sequence' do
        let(:event_classes) do
          [
            double(:event_class, name: 'TestDomain::A::A'),
            double(:event_class, name: 'TestDomain::A::B'),
          ]
        end

        it 'returns the max sequence for the aggregate and event type' do
          expect(sequence_stats.max_sequence(event_classes: event_classes)).to eq 3
        end

        context 'when no rows are returned' do
          let(:event_classes) do
            [
              double(:event_class, name: 'TestDomain::Z::Z'),
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
