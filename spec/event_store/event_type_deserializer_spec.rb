module TestDomain
  module Thing
    EventTypeDeserializerTested = Class.new(EventFramework::DomainEvent)
  end
end

module Thing
  OtherEventTypeDeserializerTested = Class.new(EventFramework::DomainEvent)
end

OtherEventTypeDeserializerTested = Class.new(EventFramework::DomainEvent)

module EventFramework
  RSpec.describe EventStore::EventTypeDeserializer do
    describe '.call' do
      context 'with an aggregate_type and an event_type' do
        it 'returns the corresponding domain event class' do
          expect(described_class.call('Thing', 'EventTypeDeserializerTested'))
            .to eq TestDomain::Thing::EventTypeDeserializerTested
        end
      end

      context 'with a missing argument' do
        it 'raises an error' do
          expect { described_class.call(nil, 'EventTypeDeserializerTested') }.to raise_error(ArgumentError)
        end
      end

      context 'with an unknown aggregate type' do
        it 'raises an error' do
          expect { described_class.call('OtherThing', 'EventTypeDeserializerTested') }
            .to raise_error described_class::UnknownEventType, 'OtherThing::EventTypeDeserializerTested'
        end
      end

      context 'with an unknown event type' do
        it 'raises an error' do
          expect { described_class.call('Thing', 'UnknownEvent') }
            .to raise_error described_class::UnknownEventType, 'Thing::UnknownEvent'
        end
      end

      context 'when called with a class name that exists outside the declared parent domain' do
        it 'raises an error' do
          expect { described_class.call('Thing', 'OtherEventTypeDeserializerTested') }
            .to raise_error described_class::UnknownEventType, 'Thing::OtherEventTypeDeserializerTested'
        end
      end
    end
  end
end
