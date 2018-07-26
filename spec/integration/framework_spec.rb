module TestEvents
  class ThingImplemented < EventFramework::DomainEvent
    attribute :foo, EventFramework::Types::Strict::String
    attribute :bar, EventFramework::Types::Strict::String
  end
end

module EventFramework
  RSpec.describe 'integration' do
    class ImplementThingHandler < CommandHandler
      def handle(id, command)
        with_aggregate(Thing, id) do |thing|
          thing.implement(foo: command.foo, bar: command.bar)
        end
      end
    end

    class ImplementThing < Command
      attribute :foo, EventFramework::Types::Strict::String
      attribute :bar, EventFramework::Types::Strict::String
    end

    class Thing < Aggregate
      attr_accessor :foo, :bar

      apply TestEvents::ThingImplemented do |body|
        self.foo = body.foo
        self.bar = body.bar
      end

      def implement(foo:, bar:)
        add TestEvents::ThingImplemented.new(foo: foo, bar: bar)
      end
    end

    it 'records an event via a command' do
      current_user_id = SecureRandom.uuid
      current_account_id = SecureRandom.uuid
      aggregate_id = SecureRandom.uuid

      handler = ImplementThingHandler.new(
        user_id: current_user_id,
        account_id: current_account_id,
      )

      command = ImplementThing.new(
        foo: 'Foo',
        bar: 'Bar',
      )

      handler.handle(aggregate_id, command)

      event = EventStore::Source.get_for_aggregate(aggregate_id).last

      expect(event.domain_event).to have_attributes(foo: 'Foo', bar: 'Bar')
    end
  end
end
