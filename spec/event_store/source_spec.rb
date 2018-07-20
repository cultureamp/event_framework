require_relative '../../lib/event_framework'
require_relative '../../lib/event'
require_relative '../../lib/event_store/source'
require_relative '../../lib/event_store/sink'
require 'securerandom'

module EventFramework
  class EventStore
    RSpec.describe Source do
      FooAdded = Class.new(Event) do
        attribute :foo, Types::String
      end

      let(:aggregate_id) { SecureRandom.uuid }

      describe '.get_from' do
        it 'returns events' do
          event_1 = FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 1, foo: 'bar', metadata: {})
          event_2 = FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 2, foo: 'baz', metadata: {})

          Sink.sink(
            aggregate_id: aggregate_id,
            events: [event_1, event_2],
          )

          expect(Source.get_from(0)).to match_events [
            FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 1, foo: 'bar', metadata: {}),
            FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 2, foo: 'baz', metadata: {}),
          ]
        end
      end

      describe 'get_for_aggregate' do
        it 'returns events scoped to the aggregate' do
          event_1 = FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 1, foo: 'bar', metadata: {})
          event_2 = FooAdded.new(aggregate_id: SecureRandom.uuid, aggregate_sequence: 2, foo: 'baz', metadata: {})
          event_3 = FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 2, foo: 'qux', metadata: {})

          Sink.sink(aggregate_id: aggregate_id, events: [event_1])
          Sink.sink(aggregate_id: event_2.aggregate_id, events: [event_2])
          Sink.sink(aggregate_id: aggregate_id, events: [event_3])

          expect(Source.get_for_aggregate(aggregate_id)).to match_events [
            FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 1, foo: 'bar', metadata: {}),
            FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence: 2, foo: 'qux', metadata: {}),
          ]
        end
      end
    end
  end
end
