module EventFramework
  RSpec.describe EventProcessorMonitor do
    describe ".call" do
      let(:sequence_stats_class) { class_double(EventStore::SequenceStats) }
      let(:sequence_stats) { instance_double(EventStore::SequenceStats) }
      let(:bookmark_1) { instance_double(BookmarkReadonly) }
      let(:bookmark_2) { instance_double(BookmarkReadonly) }
      let(:bookmark_3) { instance_double(BookmarkReadonly) }
      let(:bookmark_repository_1) { instance_double(BookmarkRepository, readonly_bookmark: bookmark_1) }
      let(:bookmark_repository_2) { instance_double(BookmarkRepository, readonly_bookmark: bookmark_2) }
      let(:bookmark_repository_3) { instance_double(BookmarkRepository, readonly_bookmark: bookmark_3) }
      let(:metrics) { double(:metrics) }
      let(:bookmark_database) { instance_spy(EventFramework::DatabaseConnection) }
      let(:sequence_stats_database) { instance_spy(EventFramework::DatabaseConnection) }
      let(:event_type_resolver) { instance_double(EventStore::EventTypeResolver) }

      subject(:event_processor_monitor) do
        described_class.new(
          sequence_stats_class: sequence_stats_class,
          metrics: metrics,
          bookmark_database: bookmark_database,
          sequence_stats_database: sequence_stats_database,
          event_type_resolver: event_type_resolver,
          sleep_interval: 0
        )
      end

      let(:handled_event_class) { double(:handled_event_class) }
      let(:event_processors) do
        [
          event_processor_class_double(
            "event_processor_class_1",
            instance_double(EventHandlerRegistry, handled_event_classes: [handled_event_class], all_handler?: false)
          ),
          event_processor_class_double(
            "event_processor_class_2",
            instance_double(EventHandlerRegistry, handled_event_classes: [handled_event_class], all_handler?: false)
          ),
          event_processor_class_double(
            "event_processor_class_3",
            instance_double(EventHandlerRegistry, handled_event_classes: [], all_handler?: true)
          )
        ]
      end

      def event_processor_class_double(name, event_handlers)
        class_double(
          EventProcessor,
          event_handlers: event_handlers,
          name: name
        )
      end

      before do
        allow(BookmarkRepository).to receive(:new)
          .with(name: "event_processor_class_1", database: bookmark_database)
          .and_return(bookmark_repository_1)
        allow(BookmarkRepository).to receive(:new)
          .with(name: "event_processor_class_2", database: bookmark_database)
          .and_return(bookmark_repository_2)
        allow(BookmarkRepository).to receive(:new)
          .with(name: "event_processor_class_3", database: bookmark_database)
          .and_return(bookmark_repository_3)

        allow(sequence_stats_class).to receive(:new)
          .with(database: sequence_stats_database, event_type_resolver: event_type_resolver)
          .and_return(sequence_stats)

        # Simulate the event processor catching up
        allow(bookmark_1).to receive(:sequence).and_return(0, 1, 3)

        # Simulate the event processor being stuck
        allow(bookmark_2).to receive(:sequence).and_return(1, 1, 1)

        # Simulate the event processor catching up
        allow(bookmark_3).to receive(:sequence).and_return(1, 2, 3)

        # Loop 3 times
        allow(event_processor_monitor).to receive(:loop)
          .and_yield
          .and_yield
          .and_yield

        # There are 3 events in the source
        allow(sequence_stats).to receive(:max_sequence).with(event_classes: [handled_event_class]).and_return(3)

        allow(sequence_stats).to receive(:max_sequence).with(no_args).and_return(3)

        allow(metrics).to receive(:call)
      end

      def monitor
        event_processor_monitor.call(processor_classes: event_processors)
      end

      it "calls metrics with processor lag metrics" do
        expect(metrics).to receive(:call).with(
          [
            {processor_class_name: "event_processor_class_1", processor_lag: 3},
            {processor_class_name: "event_processor_class_2", processor_lag: 2},
            {processor_class_name: "event_processor_class_3", processor_lag: 2}
          ]
        )
        expect(metrics).to receive(:call).with(
          [
            {processor_class_name: "event_processor_class_1", processor_lag: 2},
            {processor_class_name: "event_processor_class_2", processor_lag: 2},
            {processor_class_name: "event_processor_class_3", processor_lag: 1}
          ]
        )
        expect(metrics).to receive(:call).with(
          [
            {processor_class_name: "event_processor_class_1", processor_lag: 0},
            {processor_class_name: "event_processor_class_2", processor_lag: 2},
            {processor_class_name: "event_processor_class_3", processor_lag: 0}
          ]
        )

        monitor
      end
    end
  end
end
