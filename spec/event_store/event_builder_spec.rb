module TestDomain
  module Thing
    class EventBuilderTested < EventFramework::DomainEvent
      attribute :test, EventFramework::Types::Strict::String
    end
  end
end

module EventFramework
  RSpec.describe EventStore::EventBuilder do
    describe '.call', aggregate_failures: true do
      let(:event_id) { SecureRandom.uuid }
      let(:aggregate_id) { SecureRandom.uuid }
      let(:account_id) { SecureRandom.uuid }
      let(:user_id) { SecureRandom.uuid }
      let(:created_at) { Time.now.utc }
      let(:row) do
        {
          id: event_id,
          sequence: 1,
          aggregate_type: 'Thing',
          event_type: 'EventBuilderTested',
          aggregate_id: aggregate_id,
          aggregate_sequence: 2,
          body: {
            test: 'Testing!',
          },
          metadata: {
            account_id: account_id,
            user_id: user_id,
            created_at: created_at,
          },
        }
      end
      let(:event) { described_class.call(row) }

      it 'returns an event' do
        expect(event).to be_a Event
        expect(event.id).to eq event_id
        expect(event.sequence).to eq 1
        expect(event.type).to eq TestDomain::Thing::EventBuilderTested
        expect(event.aggregate_id).to eq aggregate_id
        expect(event.aggregate_sequence).to eq 2
      end

      it 'has a domain event' do
        expect(event.domain_event).to be_a TestDomain::Thing::EventBuilderTested
        expect(event.domain_event.test).to eq 'Testing!'
      end

      it 'has a metadata object' do
        expect(event.metadata).to be_a Event::Metadata
        expect(event.metadata.account_id).to eq account_id
        expect(event.metadata.user_id).to eq user_id
        expect(event.metadata.created_at).to eq created_at
      end
    end
  end
end
