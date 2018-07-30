require 'event_store/source/event_type_deserializer'

module TestEvents
  EventTypeDeserializerTested = Class.new(EventFramework::DomainEvent)
end

OtherEventTypeDeserializerTested = Class.new(EventFramework::DomainEvent)

module EventFramework
  module EventStore
    class Source
      RSpec.describe EventTypeDeserializer do
        describe '.call' do
          it 'returns a class' do
            expect(EventTypeDeserializer.call('EventTypeDeserializerTested'))
              .to eq TestEvents::EventTypeDeserializerTested
          end

          context 'with an unknown event type' do
            it 'raises an error' do
              expect { EventTypeDeserializer.call('BadEvent') }
                .to raise_error EventTypeDeserializer::UnknownEventType, 'BadEvent'
            end
          end

          context 'when called with a class name that exists otuside the declared parent domain' do
            it 'raises an error' do
              expect { EventTypeDeserializer.call('OtherEventTypeDeserializerTested') }
                .to raise_error EventTypeDeserializer::UnknownEventType, 'OtherEventTypeDeserializerTested'
            end
          end
        end
      end
    end
  end
end
