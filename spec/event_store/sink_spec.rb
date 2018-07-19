require 'spec_helper'
require 'event_framework'
require 'event'
require 'event_store/sink'

RSpec.describe EventFramework::EventStore::Sink do
  let(:aggregate_id) { SecureRandom.uuid }

  FooAdded = Class.new(EventFramework::Event) do
    attribute :scale, EventFramework::Types::Integer
  end

  it 'persists events to the database' do
    event = FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence_id: 1, scale: 42)

    described_class.sink(
      aggregate_id: aggregate_id,
      events: [event],
    )

    persisted_event = events_for_aggregate(aggregate_id).first

    expect(persisted_event[:body]).to eql('scale' => 42)
    expect(persisted_event[:type]).to eql 'FooAdded'
  end

  it 'allows persisting multiple events to the database' do
    event_1 = FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence_id: 1, scale: 42)
    event_2 = FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence_id: 2, scale: 43)

    described_class.sink(
      aggregate_id: aggregate_id,
      events: [event_1, event_2],
    )

    persisted_events = events_for_aggregate(aggregate_id)

    expect(persisted_events.map { |e| [e[:type], e[:body]] }).to eq [
      ['FooAdded', {'scale' => 42}],
      ['FooAdded', {'scale' => 43}],
    ]
  end

  describe 'optimistic locking' do
    context 'when the supplied aggregate_sequence_id has already been used' do
      it 'raises a concurrency error' do
        event_1 = FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence_id: 1, scale: 42)

        described_class.sink(
          aggregate_id: aggregate_id,
          events: [event_1],
        )

        # When the event was passed in the aggregate didn't know that we
        # already had a event with an aggregate_sequence_id of "1".
        event_2 = FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence_id: 1, scale: 42)

        expect {
          described_class.sink(
            aggregate_id: aggregate_id,
            events: [event_2],
          )
        }.to raise_error EventFramework::EventStore::Sink::ConcurrencyError,
          "error saving aggregate_id #{aggregate_id.inspect}, aggregate_sequence_id mismatch"
      end
    end
  end

  def events_for_aggregate(aggregate_id)
    EventFramework::EventStore
      .database
      .from(:events)
      .where(aggregate_id: aggregate_id)
      .order(:sequence_id)
  end
end
