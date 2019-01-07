module TestDomain
  module Thing
    class QuxAdded < EventFramework::DomainEvent
    end
  end
end

module EventFramework
  RSpec.describe EventProcessorWorker do
    describe '.call' do
      let(:event_processor_class) { class_double(EventProcessor, name: 'FooProjector') }
      let(:event_processor) do
        instance_double(
          EventProcessor,
          class: event_processor_class,
          handled_event_classes: [TestDomain::Thing::QuxAdded],
        )
      end
      let(:logger) { instance_double(Logger) }
      let(:events) { [] }
      let(:bookmark) { instance_double(Bookmark, sequence: 0) }
      let(:event_source) { instance_double(EventStore::Source) }

      let(:event_processor_worker_arguments) do
        {
          event_processor: event_processor,
          logger: logger,
          bookmark: bookmark,
          event_source: event_source,
        }
      end

      subject(:event_processor_worker) { described_class.new(event_processor_worker_arguments) }

      before do
        allow(logger).to receive(:info)
        allow(event_processor_worker).to receive(:sleep)
        allow(event_source).to receive(:get_after).with(0).and_return(events)

        # NOTE: Shut down after the first loop.
        allow(event_processor_worker).to receive(:shutdown_requested).and_return(false, true)
      end

      it 'logs that the process has forked' do
        expect(logger).to receive(:info).with(
          event_processor_class_name: 'FooProjector',
          msg: 'event_processor.worker.forked',
        )

        event_processor_worker.call
      end

      context 'with no events' do
        it 'sleeps' do
          expect(event_processor_worker).to receive(:sleep)

          event_processor_worker.call
        end
      end

      context 'with some events' do
        let(:events) { [event_1, event_2] }
        let(:event_1) { instance_double(Event, sequence: 1, id: SecureRandom.uuid) }
        let(:event_2) { instance_double(Event, sequence: 2, id: SecureRandom.uuid) }

        before do
          allow(event_processor).to receive(:handle_event)
          allow(bookmark).to receive(:sequence).and_return(0, 2)
          allow(bookmark).to receive(:sequence=)
        end

        it 'passes the events to the event processor' do
          expect(event_processor).to receive(:handle_event).with(event_1)
          expect(event_processor).to receive(:handle_event).with(event_2)

          event_processor_worker.call
        end

        it 'updates the bookmark sequence' do
          expect(bookmark).to receive(:sequence=).with(1)
          expect(bookmark).to receive(:sequence=).with(2)

          event_processor_worker.call
        end

        it 'logs the last processed sequence' do
          expect(logger).to receive(:info).with(
            event_processor_class_name: 'FooProjector',
            msg: 'event_processor.worker.processed_up_to',
            last_processed_event_sequence: 2,
            last_processed_event_id: events.last.id,
          )

          event_processor_worker.call
        end
      end
    end
  end
end
