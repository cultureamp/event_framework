require 'securerandom'

module TestEvents
  TodoAdded = Class.new(EventFramework::DomainEvent)
  TodoRemoved = Class.new(EventFramework::DomainEvent)
  IgnoredEvent = Class.new(EventFramework::DomainEvent)
end

module EventFramework
  RSpec.describe Aggregate do
    describe '.load_from_history' do
      let(:todo_list_class) do
        Class.new(Aggregate) do
          attr_accessor :todos, :bars, :added_removed_events

          def initialize
            @todos = 0
            @bars = 0
            @added_removed_events = 0
          end

          apply TestEvents::TodoAdded do |event|
            self.todos += 1
          end

          apply TestEvents::TodoRemoved do |event|
            self.todos -= 1
          end

          apply TestEvents::TodoAdded, TestEvents::TodoRemoved do |event|
            self.added_removed_events += 1
          end
        end
      end

      it 'loads events from history' do
        events = [
          instance_double(Event, aggregate_sequence: 1, type: TestEvents::TodoAdded, domain_event: TestEvents::TodoAdded.new),
          instance_double(Event, aggregate_sequence: 1, type: TestEvents::TodoRemoved, domain_event: TestEvents::TodoRemoved.new),
          instance_double(Event, aggregate_sequence: 1, type: TestEvents::IgnoredEvent, domain_event: TestEvents::IgnoredEvent.new),
        ]

        aggregate_id = SecureRandom.uuid

        loaded_todo_list = todo_list_class.load_from_history(aggregate_id, events)
        expect(loaded_todo_list.todos).to eq 0
        expect(loaded_todo_list.added_removed_events).to eq 2
      end
    end
  end
end
