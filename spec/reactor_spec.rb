module EventFramework
  RSpec.describe Reactor do
    let(:test_event_1) do
      Class.new(EventFramework::DomainEvent) do
        attribute :new_aggregate_id, EventFramework::Types::UUID
      end
    end
    let(:test_event_2) { Class.new(EventFramework::DomainEvent) }
    let(:aggregate_class) do
      Class.new(EventFramework::Aggregate) do
        def do_a_thing
          stage_event TestDomain::ReactorTest::TestEvent2.new
        end
      end
    end

    before do
      stub_const('TestDomain::ReactorTest::TestEvent1', test_event_1)
      stub_const('TestDomain::ReactorTest::TestEvent2', test_event_2)
      stub_const('TestDomain::ReactorTest::TestAggregate', aggregate_class)
    end

    subject(:reactor) do
      Class.new(described_class) do
        process TestDomain::ReactorTest::TestEvent1 do |_aggregate_id, domain_event, metadata|
          metadata = Metadata.new(
            account_id: metadata.account_id,
            user_id: metadata.user_id,
          )

          with_new_aggregate TestDomain::ReactorTest::TestAggregate, domain_event.new_aggregate_id, metadata: metadata do |aggregate| # rubocop:disable Style/SymbolProc
            aggregate.do_a_thing
          end
        end
      end.new
    end

    describe 'emitting events' do
      let(:metadata) { instance_double(Metadata, account_id: SecureRandom.uuid, user_id: SecureRandom.uuid) }
      let(:domain_event) { test_event_1.new(new_aggregate_id: SecureRandom.uuid) }
      let(:event) do
        instance_double(
          Event,
          domain_event: domain_event,
          aggregate_id: SecureRandom.uuid,
          metadata: metadata,
          id: SecureRandom.uuid,
        )
      end

      it 'emits an event via an aggregate' do
        reactor.handle_event(event)

        last_event = EventStore::Source.get_after(0).last

        # event
        expect(last_event.aggregate_id).to eq domain_event.new_aggregate_id
        expect(last_event.aggregate_sequence).to eq 1

        # domain event
        expect(last_event.domain_event).to be_a test_event_2

        # metadata
        expect(last_event.metadata.account_id).to eq metadata.account_id
        expect(last_event.metadata.user_id).to eq metadata.user_id
        expect(last_event.metadata.causation_id).to eq event.id
      end
    end
  end
end
