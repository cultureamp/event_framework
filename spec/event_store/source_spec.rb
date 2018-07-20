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

      describe '.get' do
        it 'returns events' do
          event_1 = FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence_id: 1, foo: 'bar', metadata: {})
          event_2 = FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence_id: 2, foo: 'baz', metadata: {})

          Sink.sink(
            aggregate_id: aggregate_id,
            events: [event_1, event_2],
          )

          expect(Source.get(0)).to match_events [
            FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence_id: 1, foo: 'bar', metadata: {}),
            FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence_id: 2, foo: 'baz', metadata: {}),
          ]
        end
      end
    end
  end
end
