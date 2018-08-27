FooTestEvent = Class.new(EventFramework::DomainEvent)

module EventFramework
  RSpec.describe EventProcessor do
    let(:event_processor_subclass) do
      Class.new(EventProcessor) do
        attr_reader :foo_test_event

        process FooTestEvent do |aggregate_id, domain_event, metadata|
          @foo_test_event = [aggregate_id, domain_event, metadata]
        end
      end
    end
    subject(:event_processor) { event_processor_subclass.new }

    describe '.handled_event_classes' do
      it 'returns the handled event classes' do
        expect(event_processor_subclass.handled_event_classes).to eq [FooTestEvent]
      end
    end

    describe '#handle_event' do
      let(:metadata) { double :metadata }
      let(:aggregate_id) { double :metadata }
      let(:domain_event) { FooTestEvent.new }
      let(:event) do
        instance_double(
          Event,
          domain_event: domain_event,
          aggregate_id: aggregate_id,
          metadata: metadata,
        )
      end

      it 'handles the event' do
        event_processor.handle_event(event)

        expect(event_processor.foo_test_event).to eq [aggregate_id, domain_event, metadata]
      end
    end
  end
end
