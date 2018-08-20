FooTestEvent = Class.new(EventFramework::DomainEvent)

module EventFramework
  RSpec.describe EventProcessor do
    let(:event_processor_subclass) do
      Class.new(EventProcessor) do
        attr_reader :foo_test_event

        process FooTestEvent do |aggregate_id, domain_event, metadata|
          @foo_test_event = [aggregate_id, domain_event, metadata]
        end

        def process_events(events)
          events.each do |event|
            handle_event(event)
          end
        end
      end
    end

    describe '.handled_event_classes' do
      it 'returns the handled event classes' do
        expect(event_processor_subclass.handled_event_classes).to eq [FooTestEvent]
      end
    end

    describe '#process_events' do
      context 'when not implemented' do
        it 'raises an error' do
          expect { described_class.new.process_events(nil) }
            .to raise_error NotImplementedError
        end
      end

      context 'when implemented by the subclass' do
        it 'handles the events' do
          event = instance_double(
            Event,
            aggregate_id: SecureRandom.uuid,
            domain_event: FooTestEvent.new,
            metadata: double(:metadata),
          )

          event_processor = event_processor_subclass.new
          event_processor.process_events([event])
          expect(event_processor.foo_test_event).to eq [
            event.aggregate_id,
            event.domain_event,
            event.metadata,
          ]
        end
      end
    end
  end
end
