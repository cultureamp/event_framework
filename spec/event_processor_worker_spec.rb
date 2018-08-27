module TestDomain
  module Thing
    class QuxAdded < EventFramework::DomainEvent
    end
  end
end

module EventFramework
  RSpec.describe EventProcessorWorker do
    describe '.call' do
      let(:event_processor_class) do
        class_double(
          EventProcessor,
          name: 'FooProjector',
          handled_event_classes: [TestDomain::Thing::QuxAdded],
        )
      end
      let(:event_processor) { instance_double(EventProcessor) }
      let(:logger) { instance_double(Logger) }
      let(:events) { [] }

      subject(:event_processor_supervisor) { described_class.new(event_processor_class: event_processor_class, logger: logger) }

      before do
        allow(logger).to receive(:info)
        allow(event_processor_class).to receive(:new).and_return(event_processor)
        allow(event_processor_supervisor).to receive(:sleep)
        allow(EventStore::Source).to receive(:get_after)
          .with(0, event_classes: [TestDomain::Thing::QuxAdded]).and_return(events)

        # NOTE: Shut down after the first loop.
        allow(event_processor_supervisor).to receive(:shutdown_requested).and_return(false, true)
      end

      it 'logs that the process has forked' do
        expect(logger).to receive(:info).with('[FooProjector] forked')

        event_processor_supervisor.call
      end

      context 'with no events' do
        it 'sleeps' do
          expect(event_processor_supervisor).to receive(:sleep)

          event_processor_supervisor.call
        end
      end

      context 'with some events' do
        let(:events) { [event_1, event_2] }
        let(:event_1) { instance_double(Event, sequence: 1) }
        let(:event_2) { instance_double(Event, sequence: 2) }
        let(:bookmark) { instance_double(Bookmark) }

        before do
          allow(event_processor).to receive(:handle_event)
          allow(BookmarkRepository).to receive(:checkout).with(name: 'FooProjector').and_return(bookmark)
          allow(bookmark).to receive(:sequence).and_return(0, 2)
          allow(bookmark).to receive(:sequence=)
        end

        it 'passes the events to the event processor' do
          expect(event_processor).to receive(:handle_event).with(event_1)
          expect(event_processor).to receive(:handle_event).with(event_2)

          event_processor_supervisor.call
        end

        it 'updates the bookmark sequence' do
          expect(bookmark).to receive(:sequence=).with(1)
          expect(bookmark).to receive(:sequence=).with(2)

          event_processor_supervisor.call
        end

        it 'logs the last processed sequence' do
          expect(logger).to receive(:info).with('[FooProjector] processed up to 2')

          event_processor_supervisor.call
        end
      end
    end
  end
end
