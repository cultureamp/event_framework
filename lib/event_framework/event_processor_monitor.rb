module EventFramework
  class EventProcessorMonitor
    SLEEP_INTERVAL = 1

    def initialize(
      logger:,
      bookmark_readonly_class: BookmarkReadonly,
      sequence_stats: EventStore::SequenceStats,
      metrics:,
      database: EventStore.database,
      sleep_interval: SLEEP_INTERVAL
    )
      @logger = logger
      @bookmark_readonly_class = bookmark_readonly_class
      @sequence_stats = sequence_stats
      @metrics = metrics
      @database = database
      @sleep_interval = sleep_interval
    end

    def call(processor_classes:)
      loop do
        processor_classes.each do |processor_class|
          processor_lag = last_event_sequence(processor_class) - last_processed_event_sequence(processor_class)

          logger.info(processor_class_name: processor_class.name, processor_lag: processor_lag.to_s)

          metrics.call(processor_class_name: processor_class.name, processor_lag: processor_lag)
        end

        sleep sleep_interval
      end
    end

    private

    attr_reader :logger, :bookmark_readonly_class, :sequence_stats, :metrics, :database, :sleep_interval

    def last_processed_event_sequence(processor_class)
      bookmark_readonly_class.new(name: processor_class.name).sequence
    end

    def last_event_sequence(processor_class)
      sequence_stats.max_sequence(event_classes: processor_class.event_handlers.handled_event_classes)
    end
  end
end
