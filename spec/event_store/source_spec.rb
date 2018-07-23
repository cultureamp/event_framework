require 'securerandom'

module TestEvents
  FooAdded = Class.new(EventFramework::Event) do
    attribute :foo, EventFramework::Types::String
  end
end

module EventFramework
  module EventStore
    RSpec.describe Source do
      let(:aggregate_id) { SecureRandom.uuid }
      let(:unpersisted_metadata) { Event::UnpersistedMetadata.new }
      let(:metadata) { Event::Metadata.new(created_at: Time.now.utc) }

      describe '.get_from' do
        it 'returns events' do
          event_1 = TestEvents::FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 1, foo: 'bar', metadata: unpersisted_metadata)
          event_2 = TestEvents::FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 2, foo: 'baz', metadata: unpersisted_metadata)

          Sink.sink(
            aggregate_id: aggregate_id,
            events: [event_1, event_2],
          )

          expect(Source.get_from(0)).to match_events [
            TestEvents::FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 1, foo: 'bar', metadata: metadata),
            TestEvents::FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 2, foo: 'baz', metadata: metadata),
          ]
        end
      end

      describe 'get_for_aggregate' do
        it 'returns events scoped to the aggregate' do
          event_1 = TestEvents::FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 1, foo: 'bar', metadata: unpersisted_metadata)
          event_2 = TestEvents::FooAdded.new(aggregate_id: SecureRandom.uuid, aggregate_sequence: 2, foo: 'baz', metadata: unpersisted_metadata)
          event_3 = TestEvents::FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 2, foo: 'qux', metadata: unpersisted_metadata)

          Sink.sink(aggregate_id: aggregate_id, events: [event_1])
          Sink.sink(aggregate_id: event_2.aggregate_id, events: [event_2])
          Sink.sink(aggregate_id: aggregate_id, events: [event_3])

          expect(Source.get_for_aggregate(aggregate_id)).to match_events [
            TestEvents::FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 1, foo: 'bar', metadata: metadata),
            TestEvents::FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 2, foo: 'qux', metadata: metadata),
          ]
        end
      end
    end
  end
end
