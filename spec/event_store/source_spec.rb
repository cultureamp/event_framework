require 'securerandom'

module TestEvents
  FooAdded = Class.new(EventFramework::Event) do
    attribute :foo, EventFramework::Types::String
  end
end

module EventFramework
  module EventStore
    RSpec.describe Source do
      def insert_event(aggregate_id:, aggregate_sequence:, type:, body:)
        EventStore.database[:events].insert(
          aggregate_id: aggregate_id,
          aggregate_sequence: aggregate_sequence,
          type: type,
          body: Sequel.pg_jsonb(body),
          metadata: Sequel.pg_jsonb(created_at: Time.now.utc),
        )
      end

      let(:aggregate_id) { SecureRandom.uuid }
      let(:unpersisted_metadata) { Event::UnpersistedMetadata.new }
      let(:metadata) { Event::Metadata.new(created_at: Time.now.utc) }

      describe '.get_from' do
        it 'returns events' do
          insert_event aggregate_id: aggregate_id, aggregate_sequence: 1, type: 'FooAdded', body: { foo: 'bar' }
          insert_event aggregate_id: aggregate_id, aggregate_sequence: 2, type: 'FooAdded', body: { foo: 'baz' }

          expect(Source.get_from(0)).to match_events [
            TestEvents::FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 1, foo: 'bar', metadata: metadata),
            TestEvents::FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 2, foo: 'baz', metadata: metadata),
          ]
        end
      end

      describe 'get_for_aggregate' do
        it 'returns events scoped to the aggregate' do
          insert_event aggregate_id: aggregate_id, aggregate_sequence: 1, type: 'FooAdded', body: { foo: 'bar' }
          insert_event aggregate_id: SecureRandom.uuid, aggregate_sequence: 2, type: 'FooAdded', body: { foo: 'baz' }
          insert_event aggregate_id: aggregate_id, aggregate_sequence: 2, type: 'FooAdded', body: { foo: 'qux' }

          expect(Source.get_for_aggregate(aggregate_id)).to match_events [
            TestEvents::FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 1, foo: 'bar', metadata: metadata),
            TestEvents::FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 2, foo: 'qux', metadata: metadata),
          ]
        end
      end
    end
  end
end
