module TestEvents
  EventTypeDeserializerTested = Class.new(EventFramework::Event)
end

module EventFramework
  module EventStore
    class Source
      RSpec.describe EventTypeDeserializer do
        describe '.call' do
          it 'returns a class' do
            expect(EventTypeDeserializer.call('EventTypeDeserializerTested'))
              .to eq TestEvents::EventTypeDeserializerTested
          end
        end
      end
    end
  end
end
