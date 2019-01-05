module EventFramework
  class EventProcessorMonitor
    SLEEP_INTERVAL = 1

    def initialize(
      logger:,
      bookmark_repository:,
      sequence_stats:,
      metrics:,
      sleep_interval: SLEEP_INTERVAL
    )
      @logger = logger
      @bookmark_repository = bookmark_repository
      @sequence_stats = sequence_stats
      @metrics = metrics
      @database = database
      @sleep_interval = sleep_interval
    end

    def call(processor_classes:)
      loop do
        cached_last_event_sequence = last_event_sequence

        processor_classes.each do |processor_class|
          processor_lag = cached_last_event_sequence - last_processed_event_sequence(processor_class)

          logger.info(processor_class_name: processor_class.name, processor_lag: processor_lag.to_s)

          metrics.call(processor_class_name: processor_class.name, processor_lag: processor_lag)
        end

        sleep sleep_interval
      end
    end

    private

    attr_reader :logger, :bookmark_repository, :sequence_stats, :metrics, :database, :sleep_interval

    def last_processed_event_sequence(processor_class)
      bookmark_repository.query(processor_class.name).sequence
    end

    def last_event_sequence
      sequence_stats.max_sequence
    end
  end
end
