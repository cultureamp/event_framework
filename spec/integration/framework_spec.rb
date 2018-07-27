module TestDomain
  class ThingImplemented < EventFramework::DomainEvent
    attribute :foo, EventFramework::Types::Strict::String
    attribute :bar, EventFramework::Types::Strict::String
  end

  class ImplementThingHandler < EventFramework::CommandHandler
    def handle(command)
      with_aggregate(ThingAggregate, command.thing_id) do |thing|
        thing.implement(command: command, metadata: metadata)
      end
    end

    def handle_many(command)
      with_aggregate(ThingAggregate, command.thing_id) do |thing|
        thing.implement_many(command: command, metadata: metadata)
      end
    end
  end

  class ImplementThing < EventFramework::Command
    attribute :thing_id, EventFramework::Types::UUID
    attribute :foo, EventFramework::Types::Strict::String
    attribute :bar, EventFramework::Types::Strict::String
  end

  class ThingAggregate < EventFramework::Aggregate
    attr_accessor :bar

    apply ThingImplemented do |body|
      # using append rather than assign so we capture the effects of cumulative
      # ThingImplemented events
      foo << body.foo
      @bar = body.bar
    end

    def foo
      @foo ||= ""
    end

    def implement(command:, metadata:)
      sink_event ThingImplemented.new(foo: command.foo, bar: command.bar), metadata
    end

    def implement_many(command:, metadata:)
      5.times do
        stage_event ThingImplemented.new(foo: command.foo, bar: command.bar), metadata
      end

      sink_staged_events
    end
  end
end

RSpec.describe 'integration' do
  let(:current_user_id)    { "2a72a921-a7e2-4ddc-a841-30c7d4723912" }
  let(:current_account_id) { "03aca38c-44ab-4eff-a86f-7e5daba33e88" }
  let(:aggregate_id)       { "ed3f5377-b063-4c53-8827-91123ca2aec6" }

  let(:metadata) do
    EventFramework::Metadata.new(
      user_id: current_account_id,
      account_id: current_account_id,
    )
  end

  let(:handler) do
    TestDomain::ImplementThingHandler.new(metadata: metadata)
  end

  let(:command) do
    TestDomain::ImplementThing.new(
      thing_id: aggregate_id,
      foo: 'X',
      bar: 'Bar',
    )
  end

  let(:events) { EventStore::Source.get_for_aggregate(aggregate_id) }

  describe 'persisting a single event from a command' do
    before { handler.handle(command) }

    it 'persists a single event' do
      expect(events.length).to eql 1
    end

    it 'persists the metadata from the command handler to the event' do
      expect(event.first.metadata).to have_attributes(user_id: current_user_id, account_id: current_account_id)
    end

    it 'persists the domain event within the event' do
      expect(event.first.domain_event).to have_attributes(foo: 'Foo', bar: 'Bar')
    end
  end

  describe 'persisting multiple events from a command' do
    before { handler.handle_many(command) }

    it 'persists multiple events' do
      expect(events.length).to eql 5
    end

    it 'persists multiple events, in order' do
      domain_event_foo_values = events.map { |e| e.domain_event.foo }

      expect(domain_event_foo_values).to eql %w(Foo FooFoo FooFooFoo FooFooFooFoo FooFooFooFooFoo)
    end
  end
end
