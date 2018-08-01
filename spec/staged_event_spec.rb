module TestDomain
  module Thing
    class LongEvent < EventFramework::DomainEvent; end

    class LongEventWithBody < EventFramework::DomainEvent
      attribute :foo, EventFramework::Types::Strict::String
    end
  end
end

ShortEvent = Class.new(EventFramework::DomainEvent)

module EventFramework
  RSpec.describe StagedEvent do
    def build_staged_event(domain_event)
      described_class.new(
        aggregate_id: 'dc7d2538-8328-47d5-9c86-14e35518eb53',
        aggregate_sequence: 1,
        domain_event: domain_event,
        metadata: EventFramework::Metadata.new(
          account_id: '3ebcebac-fef7-4216-ab2f-a73dad65a3c1',
          user_id: 'e65ab84c-ae46-4c49-88df-0a3b94ef0f8b',
          correlation_id: '864995de-6ab7-498f-aa4f-14af7b5ec008',
          causation_id: 'b59fadb2-bab2-4195-b21c-4c446926b7c9',
        ),
      )
    end

    # All domain events are implemented as classes in the form `AggregateName::EventName`,
    # with an optional preceding containing module name (e.g. Domains, TestDomain).
    # When persisting events, we only care about the last two.
    describe '#event_type' do
      it 'returns the event type of the event being staged' do
        staged_event = build_staged_event(TestDomain::Thing::LongEvent.new)

        expect(staged_event.event_type).to eql 'LongEvent'
      end
    end

    describe '#aggregate_type' do
      it 'returns the aggregate type of the event being staged' do
        staged_event = build_staged_event(TestDomain::Thing::LongEvent.new)

        expect(staged_event.aggregate_type).to eql 'Thing'
      end

      it 'raises an error if the domain event class has no container' do
        staged_event = build_staged_event(ShortEvent.new)

        expect { staged_event.aggregate_type }.to raise_error(described_class::InvalidDomainEventError)
      end
    end

    describe '#body' do
      it 'returns the contents of the domain event' do
        staged_event = build_staged_event(TestDomain::Thing::LongEventWithBody.new(foo: 'bar'))

        expect(staged_event.body).to eql(foo: 'bar')
      end
    end
  end
end
