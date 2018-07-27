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

    apply Bopped do |_event, metadata|
      bops << metadata.bop_id
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

  let(:event_sink) { spy(:event_sink) }

  let(:aggregate_id) { 'ce0507da-fc67-4300-ac23-7a11e12dbd40' }
  let(:aggregate)    { Placeholder::PlaceholderAggregate.new(aggregate_id, event_sink) }

  let(:metadata) { double :metadata, bop_id: '802ed3ee-cd97-43f7-8ec1-bd58412b0eea' }

  describe '#load_events' do
    let(:events) do
      [
        event_double(aggregate_sequence: 1, domain_event: Placeholder::Initialized.new),
        event_double(aggregate_sequence: 2, domain_event: Placeholder::Tweaked.new(tweak: "Foo!")),
        event_double(aggregate_sequence: 3, domain_event: Placeholder::Bopped.new, metadata: metadata),
        event_double(aggregate_sequence: 4, domain_event: Placeholder::IgnoredEvent.new),
      ]
    end

    before { aggregate.load_events(events) }

    it 'builds state from the given events, using the registered event handlers' do
      expect(aggregate.tweaks).to eql ["Foo!"]
      expect(aggregate.bops).to eql [metadata.bop_id]
    end

    it 'populates the (private) internal sequence' do
      expect(aggregate.send(:aggregate_sequence)).to eql events.last.aggregate_sequence
    end
  end
end
