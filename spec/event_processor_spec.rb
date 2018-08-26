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

    describe '#process_events' do
      let(:events) do
        [
          instance_double(Event, sequence: 1),
          instance_double(Event, sequence: 2),
        ]
      end
      let(:bookmark) { instance_double(Bookmark) }

      before do
        allow(event_processor).to receive(:bookmark).and_return(bookmark)
        allow(bookmark).to receive(:sequence=)
        allow(event_processor).to receive(:handle_event)
      end

      it 'calls handle event for each event individually' do
        expect(event_processor).to receive(:handle_event).with(events[0])
        expect(event_processor).to receive(:handle_event).with(events[1])

        event_processor.process_events(events)
      end

      it 'updates the bookmark for each event' do
        expect(bookmark).to receive(:sequence=).with(1)
        expect(bookmark).to receive(:sequence=).with(2)

        event_processor.process_events(events)
      end
    end
  end
end
