module TestDomain
  module Thing
    class ThingAdded < EventFramework::DomainEvent
      attribute :foo, EventFramework::Types::Strict::String
    end
  end
end

module EventFramework
  RSpec.describe 'EventProcessor integration' do
    let(:aggregate_id) { SecureRandom.uuid }
    let(:account_id) { SecureRandom.uuid }
    let(:processor_class) do
      Class.new(EventProcessor) do
        attr_reader :fake_database

        def initialize
          @fake_database = Hash.new { |h, k| h[k] = [] }
        end

        process TestDomain::Thing::ThingAdded do |aggregate_id, domain_event, metadata|
          fake_database['thing_added'] << [aggregate_id, domain_event.foo, metadata.account_id]
        end
      end
    end

    it 'processes events' do
      events = [
        Event.new(
          id: SecureRandom.uuid,
          sequence: 1,
          aggregate_sequence: 1,
          aggregate_id: aggregate_id,
          domain_event: TestDomain::Thing::ThingAdded.new(foo: 'This is the foo'),
          created_at: Time.now,
          metadata: Event::Metadata.new(
            account_id: account_id,
            user_id: SecureRandom.uuid,
          ),
        ),
      ]

      event_processor = processor_class.new
      event_processor.process_events(events)

      expect(event_processor.fake_database['thing_added']).to eq [
        [aggregate_id, 'This is the foo', account_id],
      ]
    end
  end
end
