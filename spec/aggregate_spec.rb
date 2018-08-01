module Placeholder
  class Initialized < EventFramework::DomainEvent
  end

  class Tweaked < EventFramework::DomainEvent
    attribute :tweak, EventFramework::Types::String
  end

  class Bopped < EventFramework::DomainEvent
  end

  class IgnoredEvent < EventFramework::DomainEvent
  end

  class PlaceholderAggregate < EventFramework::Aggregate
    attr_accessor :tweaks, :bops, :tweaks_and_bops_count

    apply Initialized do |_event|
      self.tweaks = []
      self.bops   = []
      self.tweaks_and_bops_count = 0
    end

    apply Tweaked do |event|
      tweaks << event.tweak
    end

    apply Bopped do |event|
      bops << event.type.to_s
    end

    apply Tweaked, Bopped do |_event|
      self.tweaks_and_bops_count += 1
    end
  end
end

RSpec.describe EventFramework::Aggregate do
  def event_double(aggregate_sequence:, domain_event:, metadata: nil)
    instance_double(
      EventFramework::Event,
      aggregate_sequence: aggregate_sequence,
      type: domain_event.class,
      domain_event: domain_event,
      metadata: metadata,
    )
  end

  let(:aggregate_id) { 'ce0507da-fc67-4300-ac23-7a11e12dbd40' }
  let(:aggregate)    { Placeholder::PlaceholderAggregate.new(aggregate_id) }

  let(:metadata) do
    EventFramework::Metadata.new(
      correlation_id: '802ed3ee-cd97-43f7-8ec1-bd58412b0eea',
      user_id: '7f86bd0e-793e-437e-9398-b9213ed482ef',
      account_id: '760ca62f-f0ba-4ad4-9471-ed4c25345cc1',
    )
  end

  let(:events) do
    [
      event_double(aggregate_sequence: 1, domain_event: Placeholder::Initialized.new),
      event_double(aggregate_sequence: 2, domain_event: Placeholder::Tweaked.new(tweak: "Foo!")),
      event_double(aggregate_sequence: 3, domain_event: Placeholder::Bopped.new, metadata: metadata),
      event_double(aggregate_sequence: 4, domain_event: Placeholder::IgnoredEvent.new),
    ]
  end

  describe '#load_events' do
    before { aggregate.load_events(events) }

    it 'builds state from the given events, using the registered event handlers' do
      expect(aggregate.tweaks).to eql ["Foo!"]
      expect(aggregate.bops).to eql ["Placeholder::Bopped"]
    end

    it 'populates the (private) internal sequence' do
      expect(aggregate.send(:aggregate_sequence)).to eql events.last.aggregate_sequence
    end
  end

  describe '#stage_event' do
    before { aggregate.load_events(events) }

    it 'builds a staged_event and stores it in staged_events' do
      aggregate.stage_event Placeholder::Bopped.new
      aggregate.stage_event Placeholder::Bopped.new

      event_matchers = [
        an_object_having_attributes(
          aggregate_id: aggregate_id,
          aggregate_sequence: 5,
          domain_event: an_instance_of(Placeholder::Bopped),
          metadata: nil,
        ),
        an_object_having_attributes(
          aggregate_id: aggregate_id,
          aggregate_sequence: 6,
          domain_event: an_instance_of(Placeholder::Bopped),
          metadata: nil,
        ),
      ]

      expect(aggregate.staged_events).to match event_matchers
    end
  end
end
