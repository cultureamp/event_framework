module EventFramework
  RSpec.describe EventProcessorSupervisor do
    describe '.call' do
      let(:event_processor_class) { class_double(EventProcessor, name: 'FooProjector') }
      let(:event_processor) { instance_double(EventProcessor) }
      let(:logger) { instance_double(Logger) }

      subject(:event_processor_supervisor) { described_class.new(event_processor_class: event_processor_class, logger: logger) }

      before do
        allow(logger).to receive(:info)
        allow(event_processor_class).to receive(:new).and_return(event_processor)

        # NOTE: Shut down after the first loop.
        allow(event_processor_supervisor).to receive(:shutdown_requested).and_return(false, true)
      end

      it 'logs that the process has forked' do
        expect(logger).to receive(:info).with('[FooProjector] forked')

        event_processor_supervisor.call
      end

      context 'with no events' do
        before do
          allow(EventStore::Source).to receive(:get_after).and_return([])
        end

        it 'sleeps' do
          expect(event_processor_supervisor).to receive(:sleep)

          event_processor_supervisor.call
        end
      end

      context 'with some events' do
        let(:events_1) { [instance_double(Event, sequence: 2), instance_double(Event, sequence: 1)] }
        let(:events_2) { [instance_double(Event, sequence: 3)] }

        before do
          allow(event_processor).to receive(:process_events)
          allow(EventStore::Source).to receive(:get_after).with(0).and_return(events_1)
          allow(EventStore::Source).to receive(:get_after).with(2).and_return(events_2)

          # NOTE: Shut down after the second loop.
          allow(event_processor_supervisor).to receive(:shutdown_requested).and_return(false, false, true)
        end

        it 'passes the events to the event processor' do
          expect(event_processor).to receive(:process_events).with(events_1)
          expect(event_processor).to receive(:process_events).with(events_2)

          event_processor_supervisor.call
        end

        it 'logs the last processed sequence' do
          expect(logger).to receive(:info).with('[FooProjector] processed up to 2')
          expect(logger).to receive(:info).with('[FooProjector] processed up to 3')

          event_processor_supervisor.call
        end
      end
    end
  end
end
