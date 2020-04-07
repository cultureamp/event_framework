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
      let(:bookmark) { instance_double(Bookmark, next: [0, false]) }
      let(:event_source) { instance_double(EventStore::Source) }
      # NOTE: Shut down after the first loop.
      let(:ready_to_stop_after) { 1 }
      let(:ready_to_stop) do
        lambda do
          @ready_to_stop ||= 0
          if @ready_to_stop == ready_to_stop_after
            throw :done
          end
          @ready_to_stop += 1
        end
      end

      let(:event_processor_worker_arguments) do
        {
          event_processor: event_processor,
          logger: logger,
          bookmark: bookmark,
          event_source: event_source,
        }
      end
      subject(:event_processor_worker) { described_class.new(event_processor_worker_arguments, &ready_to_stop) }

      before do
        allow(logger).to receive(:info)
        allow(event_source).to receive(:get_after)
          .with(0, event_classes: [TestDomain::Thing::QuxAdded]).and_return(events)
      end

      def run_event_processor_worker
        catch :done do
          event_processor_worker.call
        end
      end

      it 'logs that the process has forked' do
        expect(logger).to receive(:info).with(
          event_processor_class_name: 'FooProjector',
          msg: 'event_processor.worker.forked',
        )

        run_event_processor_worker
      end

      context 'with no events' do
        it 'sleeps' do
          expect(event_processor_worker).to receive(:sleep)

          run_event_processor_worker
        end
      end

      context 'with some events' do
        let(:events) { [event_1, event_2] }
        let(:event_1) { instance_double(Event, sequence: 1, id: SecureRandom.uuid) }
        let(:event_2) { instance_double(Event, sequence: 2, id: SecureRandom.uuid) }

        before do
          allow(event_processor).to receive(:handle_event)
          allow(bookmark).to receive(:next).and_return([0, false], [2, false])
          allow(bookmark).to receive(:sequence=)
        end

        it 'passes the events to the event processor' do
          expect(event_processor).to receive(:handle_event).with(event_1)
          expect(event_processor).to receive(:handle_event).with(event_2)

          run_event_processor_worker
        end

        it 'updates the bookmark sequence' do
          expect(bookmark).to receive(:sequence=).with(1)
          expect(bookmark).to receive(:sequence=).with(2)

          run_event_processor_worker
        end

        it 'logs a summary of the new events' do
          expect(logger).to receive(:info).with(
            event_processor_class_name: 'FooProjector',
            msg: 'event_processor.worker.new_events',
            first_event_sequence: 1,
            event_id: event_1.id,
            count: 2,
          )

          run_event_processor_worker
        end

        it 'logs the last processed sequence' do
          expect(logger).to receive(:info).with(
            event_processor_class_name: 'FooProjector',
            msg: 'event_processor.worker.processed_up_to',
            last_processed_event_sequence: 2,
            last_processed_event_id: events.last.id,
          )

          run_event_processor_worker
        end
      end

      context 'when the processor is disabled an then enabled again' do
        let(:event_1) { instance_double(Event, sequence: 1, id: SecureRandom.uuid) }
        let(:event_2) { instance_double(Event, sequence: 2, id: SecureRandom.uuid) }

        # NOTE: Shut down after the third loop.
        let(:ready_to_stop_after) { 3 }

        before do
          allow(bookmark).to receive(:next).and_return([0, false], [1, true], [1, false])
          allow(bookmark).to receive(:sequence=)
          allow(event_source).to receive(:get_after)
            .with(0, event_classes: [TestDomain::Thing::QuxAdded]).and_return([event_1])
          allow(event_source).to receive(:get_after)
            .with(1, event_classes: [TestDomain::Thing::QuxAdded]).and_return([event_2])
        end

        it 'sleeps for DISABLED_SLEEP_INTERVAL' do
          # Enabled
          expect(event_processor).to receive(:handle_event).with(event_1)

          # Disabled, sleep
          expect(event_processor_worker).to receive(:sleep).with(described_class::DISABLED_SLEEP_INTERVAL)

          # Enabled again
          expect(event_processor).to receive(:handle_event).with(event_2)

          run_event_processor_worker
        end
      end

      context 'when the event processor responds to logger=' do
        let(:event_processor) { Struct.new(:handled_event_classes, :logger).new([TestDomain::Thing::QuxAdded]) }

        it 'sets the logger' do
          expect(event_processor).to receive(:logger=).with(logger)

          run_event_processor_worker
        end
      end
    end
  end
end
