require 'spec_helper'
require_relative '../../lib/event_framework'
require_relative '../../lib/event'
require_relative '../../lib/event_store/sink'

ScaleAdded = Class.new(EventFramework::Event) do
  attribute :scale, EventFramework::Types::Integer
end

module EventFramework
  class EventStore
    RSpec.describe Sink do
      let(:aggregate_id) { SecureRandom.uuid }

      def sequence_id(column)
        EventStore.database["SELECT last_value FROM #{column}"].to_a.last[:last_value]
      end

      it 'persists events to the database', aggregate_failures: true do
        correlation_id = SecureRandom.uuid

        event = ScaleAdded.new(
          aggregate_id: aggregate_id,
          aggregate_sequence_id: 1,
          scale: 42,
          metadata: {
            correlation_id: correlation_id,
            "foo'bar" => "baz'qux",
          },
        )

        described_class.sink(
          aggregate_id: aggregate_id,
          events: [event],
        )

        persisted_events = events_for_aggregate(aggregate_id)

        expect(persisted_events.map { |row| row.reject { |k, _v| %i[metadata id].include?(k) } }).to eq [
          {
            sequence_id: sequence_id('events_sequence_id_seq'),
            aggregate_sequence_id: 1,
            aggregate_id: aggregate_id,
            type: "ScaleAdded",
            body: Sequel::Postgres::JSONBHash.new('scale' => 42),
          },
        ]

        expect(persisted_events.first[:id]).to match Types::UUID_REGEX
        expect(Time.parse(persisted_events.first[:metadata]['created_at'] + 'Z')).to be_within(1).of Time.now.utc
        expect(persisted_events.first[:metadata]["foo'bar"]).to eq "baz'qux"
      end

      it 'allows persisting multiple events to the database' do
        event_1 = ScaleAdded.new(aggregate_id: aggregate_id, aggregate_sequence_id: 1, scale: 42, metadata: {})
        event_2 = ScaleAdded.new(aggregate_id: aggregate_id, aggregate_sequence_id: 2, scale: 43, metadata: {})

        described_class.sink(
          aggregate_id: aggregate_id,
          events: [event_1, event_2],
        )

        persisted_events = events_for_aggregate(aggregate_id)

        expect(persisted_events.map { |e| [e[:type], e[:body]] }).to eq [
          ['ScaleAdded', { 'scale' => 42 }],
          ['ScaleAdded', { 'scale' => 43 }],
        ]
      end

      describe 'optimistic locking' do
        context 'when the supplied aggregate_sequence_id has already been used' do
          it 'raises a concurrency error' do
            event_1 = ScaleAdded.new(aggregate_id: aggregate_id, aggregate_sequence_id: 1, scale: 42, metadata: {})

            described_class.sink(
              aggregate_id: aggregate_id,
              events: [event_1],
            )

            # When the event was passed in the aggregate didn't know that we
            # already had a event with an aggregate_sequence_id of "1".
            event_2 = ScaleAdded.new(aggregate_id: aggregate_id, aggregate_sequence_id: 1, scale: 42, metadata: {})

            expect {
              described_class.sink(
                aggregate_id: aggregate_id,
                events: [event_2],
              )
            }.to raise_error Sink::ConcurrencyError,
                             "error saving aggregate_id #{aggregate_id.inspect}, aggregate_sequence_id mismatch"
          end
        end
      end

      def events_for_aggregate(aggregate_id)
        EventStore
          .database
          .from(:events)
          .where(aggregate_id: aggregate_id)
          .order(:sequence_id)
          .all
      end
    end
  end
end
