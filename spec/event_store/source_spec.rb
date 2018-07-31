module TestEvents
  FooAdded = Class.new(EventFramework::DomainEvent) do
    attribute :foo, EventFramework::Types::String
  end
end

module EventFramework
  module EventStore
    RSpec.describe Source do
      def insert_event(sequence:, aggregate_id:, aggregate_sequence:, type:, body:)
        metadata = {
          account_id: SecureRandom.uuid,
          user_id: SecureRandom.uuid,
          created_at: Time.now.utc,
        }

        EventStore.database[:events].overriding_system_value.insert(
          sequence: sequence,
          aggregate_id: aggregate_id,
          aggregate_sequence: aggregate_sequence,
          type: type,
          body: Sequel.pg_jsonb(body),
          metadata: Sequel.pg_jsonb(metadata),
        )
      end

      let(:aggregate_id) { SecureRandom.uuid }

      before do
        insert_event sequence: 14, aggregate_id: aggregate_id, aggregate_sequence: 1, type: 'FooAdded', body: { foo: 'foo' }
        insert_event sequence: 15, aggregate_id: SecureRandom.uuid, aggregate_sequence: 1, type: 'FooAdded', body: { foo: 'bar' }
        insert_event sequence: 16, aggregate_id: aggregate_id, aggregate_sequence: 2, type: 'FooAdded', body: { foo: 'qux' }
      end

      describe '.get_from' do
        let(:events) { Source.get_from(15) }

        it 'only returns events with a sequence value greater or equal to the given argument' do
          expect(events).to all be_an(Event)
          expect(events).to match [
            have_attributes(sequence: 15, domain_event: TestEvents::FooAdded.new(foo: 'bar')),
            have_attributes(sequence: 16, domain_event: TestEvents::FooAdded.new(foo: 'qux')),
          ]
        end

        context 'when no events are found' do
          let(:events) { Source.get_from(17) }

          it 'returns an empty array' do
            expect(events).to be_empty
          end
        end
      end

      describe '.get_for_aggregate' do
        let(:events) { Source.get_for_aggregate(aggregate_id) }

        it 'returns events scoped to the aggregate' do
          expect(events).to all be_an(Event)
          expect(events).to match [
            have_attributes(sequence: 14, domain_event: TestEvents::FooAdded.new(foo: 'foo')),
            have_attributes(sequence: 16, domain_event: TestEvents::FooAdded.new(foo: 'qux')),
          ]
        end

        context 'when no events are found' do
          let(:events) { Source.get_for_aggregate(SecureRandom.uuid) }

          it 'returns an empty array' do
            expect(events).to be_empty
          end
        end
      end

      describe '.get_for_aggregate_from' do
        let(:events) { Source.get_for_aggregate_from(aggregate_id, 2) }

        it 'returns events scoped to the aggregate' do
          expect(events).to all be_an(Event)
          expect(events).to match [
            have_attributes(sequence: 16, aggregate_sequence: 2, domain_event: TestEvents::FooAdded.new(foo: 'qux')),
          ]
        end

        context 'when no events are found' do
          let(:events) { Source.get_for_aggregate_from(SecureRandom.uuid, 1) }

          it 'returns an empty array' do
            expect(events).to be_empty
          end
        end
      end
    end
  end
end
