module TestDomain
  module Thing
    EventTypeSerializerTested = Class.new(EventFramework::DomainEvent)
  end
end

module EventFramework
  module EventStore
    RSpec.describe EventTypeSerializer do
      describe '.call' do
        it 'returns an event type description' do
          expect(described_class.call(TestDomain::Thing::EventTypeSerializerTested))
            .to eq EventTypeSerializer::EventTypeDescription.new('EventTypeSerializerTested', 'Thing')
        end
      end
    end
  end
end