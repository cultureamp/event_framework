module EventFramework
  RSpec.describe EventProcessorMonitor do
    describe '.call' do
      let(:logger) { instance_double(Logger) }
      let(:sequence_stats) { EventStore::SequenceStats }
      let(:bookmark_readonly_class) { class_double(Bookmark) }
      let(:bookmark) { instance_double(Bookmark) }
      let(:metrics) { double(:metrics) }

      subject(:event_processor_monitor) do
        described_class.new(
          logger: logger,
          sequence_stats: sequence_stats,
          bookmark_readonly_class: bookmark_readonly_class,
          metrics: metrics,
          sleep_interval: 0,
        )
      end

      let(:handled_event_class) { double(:handled_event_class) }
      let(:event_processors) do
        [
          class_double(
            EventProcessor,
            event_handlers: instance_double(EventHandlerRegistry, handled_event_classes: [handled_event_class]),
            name: 'event_processor_class_1',
          ),
        ]
      end

      before do
        allow(bookmark_readonly_class).to receive(:new).with(name: 'event_processor_class_1').and_return(bookmark)

        # Simulate the event processor catching up
        allow(bookmark).to receive(:sequence).and_return(0, 1, 3)

        # Loop 3 times
        allow(event_processor_monitor).to receive(:loop).and_yield.and_yield.and_yield

        # There are 3 events in the source
        allow(sequence_stats).to receive(:max_sequence).with(event_classes: [handled_event_class]).and_return(3)

        allow(logger).to receive(:info)
        allow(metrics).to receive(:emit_point)
      end

      def monitor
        event_processor_monitor.call(processor_classes: event_processors)
      end

      it 'logs the processor lag' do
        expect(logger).to receive(:info).with('[event_processor_class_1] 3')
        expect(logger).to receive(:info).with('[event_processor_class_1] 2')
        expect(logger).to receive(:info).with('[event_processor_class_1] 0')

        monitor
      end

      it 'sends processor lag metrics' do
        allow(metrics).to receive(:emit_point).with('murmur.event_processor_lag', 3, tags: ['processor_name:event_processor_class_1'])
        allow(metrics).to receive(:emit_point).with('murmur.event_processor_lag', 2, tags: ['processor_name:event_processor_class_1'])
        allow(metrics).to receive(:emit_point).with('murmur.event_processor_lag', 0, tags: ['processor_name:event_processor_class_1'])

        monitor
      end
    end
  end
end
