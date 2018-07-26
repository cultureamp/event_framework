module TestEvents
  FooAdded = Class.new(EventFramework::DomainEvent) do
    attribute :foo, EventFramework::Types::String
  end
end

module EventFramework
  module EventStore
    RSpec.describe Source do
      def insert_event(sequence:, aggregate_id:, aggregate_sequence:, type:, body:, metadata: {})
        EventStore.database[:events].overriding_system_value.insert(
          sequence: sequence,
          aggregate_id: aggregate_id,
          aggregate_sequence: aggregate_sequence,
          type: type,
          body: Sequel.pg_jsonb(body),
          metadata: Sequel.pg_jsonb(metadata.merge(created_at: Time.now.utc)),
        )
      end

      let(:aggregate_id) { SecureRandom.uuid }
      let(:unpersisted_metadata) { { account_id: SecureRandom.uuid, user_id: SecureRandom.uuid } }
      let(:metadata) { Event::Metadata.new(unpersisted_metadata.merge(created_at: Time.now.utc)) }

      describe '.get_from' do
        let(:events) { Source.get_from(15) }
        let(:first_event) { events.first }

        before do
          insert_event sequence: 14, aggregate_id: aggregate_id, aggregate_sequence: 1, type: 'FooAdded', body: { foo: 'bar' }, metadata: unpersisted_metadata
          insert_event sequence: 15, aggregate_id: aggregate_id, aggregate_sequence: 2, type: 'FooAdded', body: { foo: 'bar' }, metadata: unpersisted_metadata
          insert_event sequence: 16, aggregate_id: aggregate_id, aggregate_sequence: 3, type: 'FooAdded', body: { foo: 'quz' }, metadata: unpersisted_metadata
          insert_event sequence: 17, aggregate_id: aggregate_id, aggregate_sequence: 4, type: 'FooAdded', body: { foo: 'quz' }, metadata: unpersisted_metadata
        end

        it 'returns events in the expected format' do
          first_event = Source.get_from(0).first

          expect(first_event).to be_an Event
          expect(first_event).to have_attributes(aggregate_id: aggregate_id, aggregate_sequence: 1)
          expect(first_event.domain_event).to be_a TestEvents::FooAdded
          expect(first_event.domain_event).to have_attributes(foo: 'bar')
          expect(first_event.metadata.account_id).to eq unpersisted_metadata[:account_id]
          expect(first_event.metadata.user_id).to eq unpersisted_metadata[:user_id]
          expect(first_event.metadata.created_at).to be_a(Time)
        end

        it 'only returns events with a sequence value greater or equal to the given argument' do
          events = Source.get_from(15)

          expect(events.length).to eq 3
          expect(events.map(&:sequence)).to eql [15, 16, 17]
        end
      end

      describe '.get_for_aggregate' do
        it 'returns events scoped to the aggregate' do
          insert_event sequence: 1, aggregate_id: aggregate_id, aggregate_sequence: 1, type: 'FooAdded', body: { foo: 'bar' }, metadata: unpersisted_metadata
          insert_event sequence: 2, aggregate_id: SecureRandom.uuid, aggregate_sequence: 2, type: 'FooAdded', body: { foo: 'baz' }, metadata: unpersisted_metadata
          insert_event sequence: 3, aggregate_id: aggregate_id, aggregate_sequence: 2, type: 'FooAdded', body: { foo: 'qux' }, metadata: unpersisted_metadata

          events_for_aggregate = Source.get_for_aggregate(aggregate_id)

          expect(events_for_aggregate).to all be_an(Event)
          expect(events_for_aggregate).to match [
            have_attributes(sequence: 1, domain_event: TestEvents::FooAdded.new(foo: 'bar')),
            have_attributes(sequence: 3, domain_event: TestEvents::FooAdded.new(foo: 'qux')),
          ]
        end
      end
    end
  end
end
