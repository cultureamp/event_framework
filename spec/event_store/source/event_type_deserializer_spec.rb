require 'event_store/source/event_type_deserializer'

module TestEvents
  module AggregateModule
    EventTypeDeserializerTested = Class.new(EventFramework::DomainEvent)
  end
end

module AggregateModule
  OtherEventTypeDeserializerTested = Class.new(EventFramework::DomainEvent)
end

OtherEventTypeDeserializerTested = Class.new(EventFramework::DomainEvent)


RSpec.describe EventFramework::EventStore::Source::EventTypeDeserializer do
  describe '.call' do
    context 'with an aggregate_type and an event_type' do

      it 'returns the corresponding domain event class' do
        expect(described_class.call('AggregateModule', 'EventTypeDeserializerTested'))
          .to eq TestEvents::AggregateModule::EventTypeDeserializerTested
      end
    end

    context 'with a missing argument' do
      it 'raises an error' do
        expect { described_class.call(nil, 'EventTypeDeserializerTested') }.to raise_error(ArgumentError)
      end
    end

    context 'with an unknown aggregate type' do
      it 'raises an error' do
        expect { described_class.call('OtherAggregateModule', 'EventTypeDeserializerTested') }
          .to raise_error described_class::UnknownEventType, 'OtherAggregateModule::EventTypeDeserializerTested'
      end
    end

    context 'with an unknown event type' do
      it 'raises an error' do
        expect { described_class.call('AggregateModule', 'UnknownEvent') }
          .to raise_error described_class::UnknownEventType, 'AggregateModule::UnknownEvent'
      end
    end

    context 'when called with a class name that exists outside the declared parent domain' do
      it 'raises an error' do
        expect { described_class.call('AggregateModule', 'OtherEventTypeDeserializerTested') }
          .to raise_error described_class::UnknownEventType, 'AggregateModule::OtherEventTypeDeserializerTested'
      end
    end
  end
end
