module TestDomain
  module Thing
    EventTypeSerializerTested = Class.new(EventFramework::DomainEvent)
  end
end

module EventFramework
  module EventStore
    RSpec.describe EventTypeSerializer do
      subject(:event_type_serializer) { described_class.new(event_container: TestDomain) }

      describe '#call' do
        it 'returns an event type description' do
          expect(event_type_serializer.call(TestDomain::Thing::EventTypeSerializerTested))
            .to eq EventTypeSerializer::EventTypeDescription.new('EventTypeSerializerTested', 'Thing')
        end
      end
    end
  end
end
