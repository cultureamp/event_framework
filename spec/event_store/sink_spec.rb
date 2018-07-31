module TestEvents
  module ThingAggregate
    EventHappened = Class.new(EventFramework::DomainEvent)
  end
end

RSpec.describe EventFramework::EventStore::Sink do
  def build_staged_event(aggregate_sequence:)
    instance_double(
      EventFramework::StagedEvent,
      type: 'ThingAggregate::EventHappened',
      body: { foo: 'bar' },
      aggregate_id: '94cfdc57-f8ad-44b4-8ea3-ae4043c52ff5',
      aggregate_sequence: aggregate_sequence,
      metadata: metadata,
    )
  end

  let(:metadata) do
    {
      account_id: '402f0e91-c51b-4cf9-80ba-b0665fbc6f05',
      user_id: 'a64ae92d-e577-4f59-94b4-a9ec601ebdfa',
      correlation_id: '7d25a7e5-e239-4a78-9491-17cb86c541b6',
    }
  end

  def last_value_for_sequence(sequence_name)
    EventFramework::EventStore.database["SELECT last_value FROM #{sequence_name}"].to_a.last[:last_value]
  end

  def persisted_tuples_for_aggregate(aggregate_id)
    EventFramework::EventStore
      .database
      .from(:events)
      .where(aggregate_id: aggregate_id)
      .order(:sequence)
      .all
  end

  context 'persisting a single event to the database' do
    let(:events) { [build_staged_event(aggregate_sequence: 1)] }

    let(:persisted_tuple) do
      persisted_tuples_for_aggregate(events.first.aggregate_id).first
    end

    before do
      described_class.sink(events)
    end

    it 'persists the main event attributes', aggregate_failures: true do
      expect(persisted_tuple).to include(
        id: a_string_matching(EventFramework::Types::UUID_REGEX),
        sequence: last_value_for_sequence('events_sequence_seq'),
        aggregate_sequence: 1,
        aggregate_id: '94cfdc57-f8ad-44b4-8ea3-ae4043c52ff5',
        type: 'ThingAggregate::EventHappened',
      )
    end

    it 'persists the body as a JSON object' do
      body_hash = persisted_tuple[:body].to_h

      expect(body_hash).to include('foo' => 'bar')
    end

    it 'persists the metadata as a JSON object' do
      metadata_hash = persisted_tuple[:metadata].to_h

      expect(metadata_hash).to include(
        'account_id'     => '402f0e91-c51b-4cf9-80ba-b0665fbc6f05',
        'user_id'        => 'a64ae92d-e577-4f59-94b4-a9ec601ebdfa',
        'correlation_id' => '7d25a7e5-e239-4a78-9491-17cb86c541b6',
      )
    end

    it 'generates a timestamp within the metadata object' do
      timestamp = persisted_tuple[:metadata]['created_at']

      expect(Time.parse(timestamp)).to be_within(2).of Time.now.utc
    end
  end

  context 'when persisting multiple events' do
    let(:staged_events) do
      [
        build_staged_event(aggregate_sequence: 1),
        build_staged_event(aggregate_sequence: 2),
        build_staged_event(aggregate_sequence: 3),
      ]
    end

    let(:persisted_tuples) do
      persisted_tuples_for_aggregate(staged_events.first.aggregate_id)
    end

    it 'persists multiple events in one call' do
      described_class.sink(staged_events)

      expect(persisted_tuples.length).to eql 3
      expect(persisted_tuples.map { |t| t[:aggregate_sequence] }).to contain_exactly(1, 2, 3)
    end

    it 'returns the newly persisted events from the database' do
      aggregate_id = staged_events.first.aggregate_id

      expect(described_class.sink(staged_events)).to match [
        an_object_having_attributes(
          aggregate_id: aggregate_id,
          aggregate_sequence: 1,
          domain_event: an_instance_of(TestEvents::ThingAggregate::EventHappened),
          metadata: an_object_having_attributes(**metadata.to_h),
        ),
        an_object_having_attributes(
          aggregate_id: aggregate_id,
          aggregate_sequence: 2,
          domain_event: an_instance_of(TestEvents::ThingAggregate::EventHappened),
          metadata: an_object_having_attributes(**metadata.to_h),
        ),
        an_object_having_attributes(
          aggregate_id: aggregate_id,
          aggregate_sequence: 3,
          domain_event: an_instance_of(TestEvents::ThingAggregate::EventHappened),
          metadata: an_object_having_attributes(**metadata.to_h),
        ),
      ]
    end
  end

  describe 'optimistic locking' do
    context 'when the supplied aggregate_sequence has already been used' do
      let(:events) { [build_staged_event(aggregate_sequence: 1)] }

      before do
        described_class.sink(events)
      end

      it 'raises a concurrency error' do
        expect { described_class.sink(events) }.to raise_error described_class::ConcurrencyError
      end

      it 'does not persist the event' do
        expect(persisted_tuples_for_aggregate(events.first.aggregate_id).length).to eql 1
      end
    end
  end

  describe 'when passed no events' do
    it 'returns an empty array' do
      expect(described_class.sink([])).to be_empty
    end

    it 'does not call the database' do
      expect(described_class).to_not receive(:database)

      described_class.sink([])
    end
  end
end
