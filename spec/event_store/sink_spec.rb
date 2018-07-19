require 'spec_helper'
require 'event_store/sink'

EventMocked = Struct.new(:aggregate_id, :scale)

RSpec.describe EventFramework::EventStore::Sink do
  let(:aggregate_id) { SecureRandom.uuid }

  it 'persists events to the database' do
    event = EventMocked.new(aggregate_id, 42)

    described_class.sink aggregate_id: aggregate_id, events: [event]

    persisted_event = events_for_aggregate(aggregate_id).first

    expect(persisted_event[:body]).to eql('scale' => 42)
    expect(persisted_event[:type]).to eql 'EventMocked'
  end

  it 'allows persisting multiple events to the database' do
    event_1 = EventMocked.new(aggregate_id, 42)
    event_2 = EventMocked.new(aggregate_id, 43)

    described_class.sink aggregate_id: aggregate_id, events: [event_1, event_2]

    persisted_events = events_for_aggregate(aggregate_id)

    expect(persisted_events.map { |e| [e[:type], e[:body]] }).to eq [
      ['EventMocked', {'scale' => 42}],
      ['EventMocked', {'scale' => 43}],
    ]
  end

  def events_for_aggregate(aggregate_id)
    EventFramework::EventStore
      .database
      .from(:events)
      .where(aggregate_id: aggregate_id)
  end
end
