module EventFramework
  RSpec.describe Reactor do
    let(:sink) { TestDomain.container.resolve('event_store.sink') }
    let(:source) { TestDomain.container.resolve('event_store.source') }

    describe 'emitting events' do
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
            metadata = Event::Metadata.new(
              account_id: metadata.account_id,
              user_id: metadata.user_id,
            )

            with_new_aggregate TestDomain::ReactorTest::TestAggregate, domain_event.new_aggregate_id, metadata: metadata do |aggregate| # rubocop:disable Style/SymbolProc
              aggregate.do_a_thing
            end
          end

          process TestDomain::ReactorTest::TestEvent2 do |aggregate_id, _domain_event, metadata|
            metadata = Event::Metadata.new(
              account_id: metadata.account_id,
              user_id: metadata.user_id,
            )

            with_aggregate TestDomain::ReactorTest::TestAggregate, aggregate_id, metadata: metadata do |aggregate|
              aggregate.do_a_thing
            end
          end
        end.new(repository: Repository.new(sink: sink, source: source))
      end

      let(:metadata) { instance_double(Event::Metadata, account_id: SecureRandom.uuid, user_id: SecureRandom.uuid) }
      let(:domain_event) { test_event_1.new(new_aggregate_id: SecureRandom.uuid) }
      let(:event) { build_event(domain_event: domain_event, metadata: metadata) }

      it 'emits an event via an aggregate' do
        reactor.handle_event(event)

        last_event = source.get_after(0).last

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

      context 'when a concurrency exception occurs' do
        let(:domain_event) { test_event_2.new }

        it 'retries saving the event' do
          sink.sink [
            EventFramework::StagedEvent.new(
              aggregate_id: event.aggregate_id,
              aggregate_sequence: 1,
              domain_event: test_event_1.new(new_aggregate_id: SecureRandom.uuid),
              metadata: Event::Metadata.new(
                account_id: metadata.account_id,
                user_id: metadata.user_id,
              ),
            ),
          ]

          # Cause a concurrency error by setting the aggregate_sequence to 0
          original_source_get_for_aggregate = source.method(:get_for_aggregate)
          simulate_concurrency_error = true
          allow(source).to receive(:get_for_aggregate) do |aggregate_id|
            events = original_source_get_for_aggregate.call(aggregate_id)
            if simulate_concurrency_error
              simulate_concurrency_error = false
              events.map { |e| e.new(aggregate_sequence: 0) }
            else
              events
            end
          end

          reactor.handle_event(event)
        end
      end
    end

    # This is testing with_aggregate and with_new_aggregate functionality.
    describe 'causation_id' do
      let(:test_event_1) { Class.new(EventFramework::DomainEvent) }
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
          process TestDomain::ReactorTest::TestEvent1 do |_aggregate_id, _domain_event, metadata|
            with_new_aggregate TestDomain::ReactorTest::TestAggregate, SecureRandom.uuid, metadata: metadata do |aggregate| # rubocop:disable Style/SymbolProc
              aggregate.do_a_thing
            end
          end

          process TestDomain::ReactorTest::TestEvent2 do |aggregate_id, _domain_event, metadata|
            with_aggregate TestDomain::ReactorTest::TestAggregate, aggregate_id, metadata: metadata do |aggregate|
              aggregate.do_a_thing
            end
          end
        end.new(repository: Repository.new(sink: sink, source: source))
      end
      let(:existing_aggregate_id) { SecureRandom.uuid }

      # This event exercises with_aggregate
      let(:event_1) { build_event(domain_event: test_event_1.new, metadata: metadata) }
      # This event exercises with_new_aggregate, therefore we need to set up an
      # existing_aggregate_id by sinking event below.
      let(:event_2) { build_event(aggregate_id: existing_aggregate_id, domain_event: test_event_2.new, metadata: metadata) }

      before do
        sink.sink [
          EventFramework::StagedEvent.new(
            aggregate_id: existing_aggregate_id,
            aggregate_sequence: 1,
            domain_event: test_event_1.new,
            metadata: Event::Metadata.new(
              account_id: metadata.account_id,
              user_id: metadata.user_id,
            ),
          ),
        ]
      end

      context 'with a causation_id' do
        let(:metadata) { Event::Metadata.new(causation_id: SecureRandom.uuid, account_id: SecureRandom.uuid, user_id: SecureRandom.uuid) }

        it 'keeps the existing causation_id' do
          reactor.handle_event(event_1)
          reactor.handle_event(event_2)

          expect(source.get_after(0).last(2).map { |e| e.metadata.causation_id }).to eq [
            metadata.causation_id,
            metadata.causation_id,
          ]
        end
      end

      context 'with no causation_id' do
        let(:metadata) { Event::Metadata.new(account_id: SecureRandom.uuid, user_id: SecureRandom.uuid) }

        it 'uses the event ID' do
          reactor.handle_event(event_1)
          reactor.handle_event(event_2)

          expect(source.get_after(0).last(2).map { |e| e.metadata.causation_id }).to eq [
            event_1.id,
            event_2.id,
          ]
        end
      end
    end

    def build_event(aggregate_id: SecureRandom.uuid, domain_event:, metadata:)
      instance_double(
        Event,
        domain_event: domain_event,
        aggregate_id: aggregate_id,
        created_at: Time.now,
        metadata: metadata,
        id: SecureRandom.uuid,
      )
    end
  end
end
