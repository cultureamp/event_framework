module TestDomain
  module Thing
    class ThingImplemented < EventFramework::DomainEvent
      attribute :foo, EventFramework::Types::Strict::String
      attribute :bar, EventFramework::Types::Strict::String
    end

    class ImplementThingHandler < EventFramework::CommandHandler
      def handle(command)
        with_aggregate(ThingAggregate, command.thing_id) do |thing|
          thing.implement(foo: command.foo, bar: command.bar)
        end
      end

      def handle_many(command)
        with_aggregate(ThingAggregate, command.thing_id) do |thing|
          thing.implement(foo: command.foo, bar: command.bar)
          thing.implement_many(foo: command.foo, bar: command.bar)
        end
      end
    end

    class ImplementThing < EventFramework::Command
      attribute :thing_id, EventFramework::Types::UUID
      attribute :foo, EventFramework::Types::Strict::String
      attribute :bar, EventFramework::Types::Strict::String
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

  let(:handler) do
    TestDomain::Thing::ImplementThingHandler.new(metadata: metadata)
  end

  let(:command) do
    TestDomain::Thing::ImplementThing.new(
      thing_id: aggregate_id,
      foo: 'Foo',
      bar: 'Bar',
    )
  end

  let(:events) { EventFramework::EventStore::Source.get_for_aggregate(aggregate_id) }

  describe 'persisting a single event from a command' do
    let(:after_sink_hook) { spy(:after_sink_hook) }

    before do
      allow(EventFramework.config).to receive(:after_sink_hook).and_return(after_sink_hook)
      handler.handle(command)
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
  end

  describe 'persisting multiple events from a command' do
    before { handler.handle_many(command) }

    it 'persists multiple events' do
      expect(events.length).to eql 6
    end

    it 'persists multiple events, in order' do
      domain_event_foo_values = events.map { |e| e.domain_event.foo }

      expect(domain_event_foo_values).to eql %w(Foo Foo-0 Foo-1 Foo-2 Foo-3 Foo-4)
    end
  end
end
