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
    def build_metadata(**metadata_attrs)
      EventFramework::Metadata.new(
        account_id: '3ebcebac-fef7-4216-ab2f-a73dad65a3c1',
        user_id: 'e65ab84c-ae46-4c49-88df-0a3b94ef0f8b',
        correlation_id: '864995de-6ab7-498f-aa4f-14af7b5ec008',
        causation_id: 'b59fadb2-bab2-4195-b21c-4c446926b7c9',
        **metadata_attrs,
      )
    end

    def build_staged_event(domain_event, metadata: build_metadata)
      described_class.new(
        aggregate_id: 'dc7d2538-8328-47d5-9c86-14e35518eb53',
        aggregate_sequence: 1,
        domain_event: domain_event,
        mutable_metadata: metadata,
      )
    end

    describe '#body' do
      it 'returns the contents of the domain event' do
        staged_event = build_staged_event(TestDomain::Thing::LongEventWithBody.new(foo: 'bar'))

        expect(staged_event.body).to eql(foo: 'bar')
      end
    end

    describe '#metadata.to_h' do
      it 'only includes values that have been explicitly set' do
        migrated_staged_event = build_staged_event(TestDomain::Thing::LongEventWithBody.new(foo: 'bar'), metadata: build_metadata(migrated: true))
        staged_event = build_staged_event(TestDomain::Thing::LongEventWithBody.new(foo: 'bar'))

        expect(migrated_staged_event.metadata.to_h).to include(migrated: true)
        expect(staged_event.metadata.to_h).not_to have_key(:migrated)
      end
    end
  end
end
