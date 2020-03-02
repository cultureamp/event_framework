module EventFramework
  RSpec.describe EventStore do
    describe "sinking and loading events integration" do
      let(:test_event) { Class.new(EventFramework::DomainEvent) }
      let(:aggregate_id) { SecureRandom.uuid }

      let(:sink) { TestDomain.container.resolve('event_store.sink') }
      let(:source) { TestDomain.container.resolve('event_store.source') }

      before do
        stub_const('TestDomain::EventStoreTest::TestEvent', test_event)
      end

      it "with normal metadata" do
        metadata = Event::Metadata.new(
          account_id: SecureRandom.uuid,
          user_id: SecureRandom.uuid,
          correlation_id: SecureRandom.uuid,
        )
        staged_event = build_staged_event(metadata: metadata)

        expect do
          sink.sink([staged_event])
          source.get_after(0)
        end.to_not raise_error
      end

      it "with unattributed metadata" do
        metadata = Event::UnattributedMetadata.new(
          account_id: SecureRandom.uuid,
          correlation_id: SecureRandom.uuid,
        )
        staged_event = build_staged_event(metadata: metadata)

        expect do
          sink.sink([staged_event])
          source.get_after(0)
        end.to_not raise_error
      end

      def build_staged_event(metadata:)
        StagedEvent.new(
          domain_event: test_event.new,
          aggregate_id: aggregate_id,
          aggregate_sequence: 0,
          aggregate_type: 'EventStoreTest',
          event_type: 'TestEvent',
          metadata: metadata,
        )
      end
    end
  end
end
