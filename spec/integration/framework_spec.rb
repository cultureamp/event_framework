module TestDomain
  module Thing
    class ThingImplemented < EventFramework::DomainEvent
      attribute :foo, EventFramework::Types::Strict::String
      attribute :bar, EventFramework::Types::Strict::String
    end

    class ImplementThing < EventFramework::Command
      attribute :foo, EventFramework::Types::Strict::String
      attribute :bar, EventFramework::Types::Strict::String
    end

    class ImplementThings < EventFramework::Command
      attribute :foo, EventFramework::Types::Strict::String
      attribute :bar, EventFramework::Types::Strict::String

      validation_schema do
        required(:foo).filled(:str?)
        required(:bar).filled(:str?)
      end
    end

    class ImplementThingHandler < EventFramework::CommandHandler
      handle ImplementThing do |command, _metadata, _executor|
        with_new_aggregate(ThingAggregate, command.aggregate_id) do |thing|
          thing.implement(foo: command.foo, bar: command.bar)
        end
      end
    end

    class ExistingImplementThingHandler < EventFramework::CommandHandler
      handle ImplementThing do |command, _metadata, _executor|
        with_aggregate(ThingAggregate, command.aggregate_id) do |thing|
          thing.implement(foo: command.foo, bar: command.bar)
        end
      end
    end

    class ImplementThingsHandler < EventFramework::CommandHandler
      handle ImplementThings do |command, _metadata, _executor|
        with_new_aggregate(ThingAggregate, command.aggregate_id) do |thing|
          thing.implement(foo: command.foo, bar: command.bar)
          thing.implement_many(foo: command.foo, bar: command.bar)
        end
      end
    end

    class ThingAggregate < EventFramework::Aggregate
      apply ThingImplemented do |body|
        @foo = body.foo
        @bar = body.bar
      end

      def implement(foo:, bar:)
        stage_event ThingImplemented.new(foo: foo, bar: bar)
      end

      def implement_many(foo:, bar:)
        5.times do |i|
          stage_event ThingImplemented.new(foo: "#{foo}-#{i}", bar: bar)
        end
      end
    end
  end
end

RSpec.describe 'integration' do
  let(:current_user_id)    { "2a72a921-a7e2-4ddc-a841-30c7d4723912" }
  let(:current_account_id) { "03aca38c-44ab-4eff-a86f-7e5daba33e88" }
  let(:request_id)         { "ae8a5823-7886-43d7-9487-32e2e7c01e70" }

  let(:aggregate_id)       { "ed3f5377-b063-4c53-8827-91123ca2aec6" }

  let(:metadata) do
    EventFramework::Metadata.new(
      user_id: current_user_id,
      account_id: current_account_id,
      correlation_id: request_id,
    )
  end

  let(:events) { EventFramework::EventStore::Source.get_for_aggregate(aggregate_id) }

  describe 'persisting a single event from a command' do
    let(:after_sink_hook) { spy(:after_sink_hook) }
    let(:existing_events) { [] }

    let(:handler) do
      TestDomain::Thing::ImplementThingHandler.new
    end

    let(:command) do
      TestDomain::Thing::ImplementThing.new(
        aggregate_id: aggregate_id,
        foo: 'Foo',
        bar: 'Bar',
      )
    end

    before do
      EventFramework::EventStore::Sink.sink(existing_events)
      allow(EventFramework.config).to receive(:after_sink_hook).and_return(after_sink_hook)
      handler.handle(command: command, metadata: metadata, executor: nil)
    end

    it 'persists a single event' do
      expect(events.length).to eql 1
    end

    it 'persists the metadata from the command handler to the event' do
      expect(events.first.metadata).to have_attributes(
        user_id: current_user_id,
        account_id: current_account_id,
        correlation_id: request_id,
      )
    end

    it 'persists the domain event within the event' do
      expect(events.first.domain_event).to have_attributes(foo: 'Foo', bar: 'Bar')
    end

    it 'calls the after sink hook with the sunk events' do
      expect(after_sink_hook).to have_received(:call) do |events|
        expect(events).to all be_a(EventFramework::Event)
        expect(events).to match [
          an_object_having_attributes(aggregate_id: aggregate_id, aggregate_sequence: 1),
        ]
      end
    end

    context 'with an existing event' do
      let(:existing_events) do
        [
          EventFramework::StagedEvent.new(
            aggregate_id: aggregate_id,
            aggregate_sequence: 1,
            domain_event: TestDomain::Thing::ThingImplemented.new(foo: 'Foo existing', bar: 'Bar existing'),
            mutable_metadata: metadata,
          ),
        ]
      end
      let(:handler) do
        TestDomain::Thing::ExistingImplementThingHandler.new
      end

      it 'persists the event with an incremented aggregate_sequence' do
        expect(events).to match [
          an_object_having_attributes(aggregate_sequence: 1, domain_event: an_object_having_attributes(foo: 'Foo existing', bar: 'Bar existing')),
          an_object_having_attributes(aggregate_sequence: 2, domain_event: an_object_having_attributes(foo: 'Foo', bar: 'Bar')),
        ]
      end
    end
  end

  describe 'persisting multiple events from a command' do
    let(:handler) do
      TestDomain::Thing::ImplementThingsHandler.new
    end

    let(:command) do
      TestDomain::Thing::ImplementThings.new(
        aggregate_id: aggregate_id,
        foo: 'Foo',
        bar: 'Bar',
      )
    end
    before { handler.handle(command: command, metadata: metadata, executor: nil) }

    it 'persists multiple events' do
      expect(events.length).to eql 6
    end

    it 'persists multiple events, in order' do
      domain_event_foo_values = events.map { |e| e.domain_event.foo }

      expect(domain_event_foo_values).to eql %w(Foo Foo-0 Foo-1 Foo-2 Foo-3 Foo-4)
    end
  end

  describe 'validating params for a command' do
    subject(:result) { TestDomain::Thing::ImplementThings.validate(params) }

    context 'with valid params' do
      let(:aggregate_id) { SecureRandom.uuid }
      let(:params) do
        {
          aggregate_id: aggregate_id,
          'foo' => 'Foo',
          bar: 'Bar',
        }
      end

      it 'returns a successful result object' do
        expect(result).to be_success
      end

      it 'returns an output hash with symbolized keys' do
        expect(result.output).to eq(
          aggregate_id: aggregate_id,
          foo: 'Foo',
          bar: 'Bar',
        )
      end
    end

    context 'with invalid params' do
      let(:params) do
        {
          aggregate_id: SecureRandom.uuid,
          foo: 1,
          bar: 'x',
        }
      end

      it 'returns a failure result object' do
        expect(result).to be_failure
      end

      it 'returns errrors' do
        expect(result.errors).to eq(
          foo: ['must be a string'],
        )
      end
    end
  end
end
