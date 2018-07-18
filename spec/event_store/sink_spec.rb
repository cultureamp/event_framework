require 'spec_helper'
require 'event_store/sink'

EventMocked = Struct.new(:aggregate_id, :scale)

RSpec.describe EventFramework::EventStore::Sink do
  let(:aggregate_id) { SecureRandom.uuid }

  before do
    event = EventMocked.new(aggregate_id, 42)
    described_class.sink event
  end

  it 'persists events to the database' do
    persisted_event = EventFramework::EventStore
                        .database
                        .from(:events)
                        .where(aggregate_id: aggregate_id)
                        .first

    expect(persisted_event[:body]).to eql('scale' => 42)
    expect(persisted_event[:type]).to eql 'EventMocked'
  end
end
