module TestDomain
  module Thing
    class FooAdded < EventFramework::DomainEvent
      attribute :foo, EventFramework::Types::String
    end

    class BarAdded < EventFramework::DomainEvent
      attribute :bar, EventFramework::Types::String
    end
  end
end

module EventFramework
  RSpec.describe EventStore::Source do
    let(:database) { EventFramework.test_database }

    def insert_event(sequence:, aggregate_id:, aggregate_sequence:, aggregate_type:, event_type:, body:)
      metadata = {
        account_id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
      }

      database[:events].overriding_system_value.insert(
        sequence: sequence,
        aggregate_id: aggregate_id,
        aggregate_sequence: aggregate_sequence,
        aggregate_type: aggregate_type,
        event_type: event_type,
        body: Sequel.pg_jsonb(body),
        metadata: Sequel.pg_jsonb(metadata),
      )
    end

    let(:aggregate_id) { SecureRandom.uuid }

    subject { described_class.new(database: database) }

    before do
      insert_event sequence: 14, aggregate_id: aggregate_id, aggregate_sequence: 1, aggregate_type: 'Thing', event_type: 'FooAdded', body: { foo: 'foo' }
      insert_event sequence: 15, aggregate_id: SecureRandom.uuid, aggregate_sequence: 1, aggregate_type: 'Thing', event_type: 'FooAdded', body: { foo: 'bar' }
      insert_event sequence: 16, aggregate_id: aggregate_id, aggregate_sequence: 2, aggregate_type: 'Thing', event_type: 'BarAdded', body: { bar: 'qux' }
    end

    describe '.get_after' do
      let(:events) { subject.get_after(14) }

      it 'only returns events with a sequence value greater or equal to the given argument' do
        expect(events).to all be_an(Event)
        expect(events).to match [
          have_attributes(sequence: 15, domain_event: TestDomain::Thing::FooAdded.new(foo: 'bar')),
          have_attributes(sequence: 16, domain_event: TestDomain::Thing::BarAdded.new(bar: 'qux')),
        ]
      end

      context 'when no events are found' do
        let(:events) { subject.get_after(16) }

        it 'returns an empty array' do
          expect(events).to be_empty
        end
      end
    end

    describe '.get_for_aggregate' do
      let(:events) { subject.get_for_aggregate(aggregate_id) }

      it 'returns events scoped to the aggregate' do
        expect(events).to all be_an(Event)
        expect(events).to match [
          have_attributes(sequence: 14, domain_event: TestDomain::Thing::FooAdded.new(foo: 'foo')),
          have_attributes(sequence: 16, domain_event: TestDomain::Thing::BarAdded.new(bar: 'qux')),
        ]
      end

      context 'when no events are found' do
        let(:events) { subject.get_for_aggregate(SecureRandom.uuid) }

        it 'returns an empty array' do
          expect(events).to be_empty
        end
      end
    end
  end
end
