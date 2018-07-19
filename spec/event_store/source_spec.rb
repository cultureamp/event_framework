require 'spec_helper'
require 'event_framework'
require 'event'
require 'event_store/source'

module EventFramework
  class EventStore
    RSpec.describe Source do
      FooAdded = Class.new(Event) do
        attribute :foo, Types::String
      end

      let(:aggregate_id) { SecureRandom.uuid }

      it 'returns events' do
        event_1 = FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence_id: 1, foo: 'bar')
        event_2 = FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence_id: 2, foo: 'baz')

        Sink.sink(
          aggregate_id: aggregate_id,
          events: [event_1, event_2],
        )

        expect(Source.get(0)).to eq [
          FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence_id: 1, foo: 'bar'),
          FooAdded.new(aggregate_id: aggregate_id, aggregate_sequence_id: 2, foo: 'baz'),
        ]
      end
    end
  end
end
