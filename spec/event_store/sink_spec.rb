module TestEvents
  ScaleAdded = Class.new(EventFramework::DomainEvent) do
    attribute :scale, EventFramework::Types::Integer
  end
end

module EventFramework
  module EventStore
    RSpec.describe Sink do
      let(:aggregate_id) { SecureRandom.uuid }
      let(:metadata) { { account_id: SecureRandom.uuid, user_id: SecureRandom.uuid } }

      def sequence(column)
        EventStore.database["SELECT last_value FROM #{column}"].to_a.last[:last_value]
      end

      it 'persists events to the database', aggregate_failures: true do
        event = TestEvents::ScaleAdded.new(scale: 42)

        described_class.sink(
          aggregate_id: aggregate_id,
          events: [event],
          metadata: metadata,
          expected_current_aggregate_sequence: 0,
        )

        persisted_events = events_for_aggregate(aggregate_id)

        expect(persisted_events.map { |row| row.reject { |k, _v| %i[metadata id].include?(k) } }).to eq [
          {
            sequence: sequence('events_sequence_seq'),
            aggregate_sequence: 1,
            aggregate_id: aggregate_id,
            type: "ScaleAdded",
            body: Sequel::Postgres::JSONBHash.new('scale' => 42),
          },
        ]

        expect(persisted_events.first[:id]).to match Types::UUID_REGEX
        expect(Time.parse(persisted_events.first[:metadata]['created_at'])).to be_within(2).of Time.now.utc
      end

      it 'allows persisting multiple events to the database' do
        event_1 = TestEvents::ScaleAdded.new(scale: 42)
        event_2 = TestEvents::ScaleAdded.new(scale: 43)

        described_class.sink(
          aggregate_id: aggregate_id,
          events: [event_1, event_2],
          metadata: metadata,
          expected_current_aggregate_sequence: 0,
        )

        persisted_events = events_for_aggregate(aggregate_id)

        expect(persisted_events.map { |e| [e[:type], e[:body]] }).to eq [
          ['ScaleAdded', { 'scale' => 42 }],
          ['ScaleAdded', { 'scale' => 43 }],
        ]
      end

      describe 'optimistic locking' do
        context 'when the supplied aggregate_sequence has already been used' do
          it 'raises a concurrency error' do
            event_1 = TestEvents::ScaleAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 1, scale: 42, metadata: metadata)

            described_class.sink(
              aggregate_id: aggregate_id,
              events: [event_1],
              metadata: metadata,
              expected_current_aggregate_sequence: 0,
            )

            # When the event was passed in the aggregate didn't know that we
            # already had a event with an aggregate_sequence of "1".
            event_2 = TestEvents::ScaleAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 1, scale: 42, metadata: metadata)

            expect {
              described_class.sink(
                aggregate_id: aggregate_id,
                events: [event_2],
                metadata: metadata,
                expected_current_aggregate_sequence: 0,
              )
            }.to raise_error Sink::ConcurrencyError,
                             "error saving aggregate_id #{aggregate_id.inspect}, aggregate_sequence mismatch"
          end
        end
      end

      def events_for_aggregate(aggregate_id)
        EventStore
          .database
          .from(:events)
          .where(aggregate_id: aggregate_id)
          .order(:sequence)
          .all
      end
    end
  end
end
