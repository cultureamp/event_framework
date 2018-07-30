require 'spec_helper'

RSpec.describe EventFramework::StagedEvent do
  def build_staged_event(domain_event)
    described_class.new(
      aggregate_id: 'dc7d2538-8328-47d5-9c86-14e35518eb53',
      aggregate_sequence: 1,
      domain_event: domain_event,
      metadata: {
        account_id: '3ebcebac-fef7-4216-ab2f-a73dad65a3c1',
        user_id: 'e65ab84c-ae46-4c49-88df-0a3b94ef0f8b',
        correlation_id: '864995de-6ab7-498f-aa4f-14af7b5ec008',
        causation_id: 'b59fadb2-bab2-4195-b21c-4c446926b7c9',
      },
    )
  end

  module ReallyLong
    module Container
      module Aggregate
        LongEvent = Class.new(EventFramework::DomainEvent)
      end
    end
  end

  ShortEvent = Class.new(EventFramework::DomainEvent)

  ShortEventWithBody = Class.new(EventFramework::DomainEvent) do
    transform_keys(&:to_sym)

    attribute :foo, EventFramework::Types::Strict::String
  end

  describe '#type' do
    # We assume all domain events are implemented in the
    # form `AggregateName::EventName`, with an optional preceding containing
    # module name (e.g. Domains, TestDomain). We only care about the last two.
    it 'returns the canonical name of the event being staged' do
      staged_event = build_staged_event(ReallyLong::Container::Aggregate::LongEvent.new)

      expect(staged_event.type).to eql 'Aggregate::LongEvent'
    end

    it 'returns the short-form for domain events that have no container' do
      staged_event = build_staged_event(ShortEvent.new)

      expect(staged_event.type).to eql 'ShortEvent'
    end
  end

  describe '#body' do
    it 'returns the contents of the domain event' do
      staged_event = build_staged_event(ShortEventWithBody.new(foo: 'bar'))

      expect(staged_event.body).to eql(foo: 'bar')
    end
  end
end
