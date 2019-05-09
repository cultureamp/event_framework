module EventFramework
  class EventProcessorMonitor
    SLEEP_INTERVAL = 1

    def initialize(
      bookmark_readonly_class: BookmarkReadonly,
      sequence_stats: EventStore::SequenceStats,
      metrics:,
      database:,
      sleep_interval: SLEEP_INTERVAL
    )
      @bookmark_readonly_class = bookmark_readonly_class
      @sequence_stats = sequence_stats
      @metrics = metrics
      @database = database
      @sleep_interval = sleep_interval
    end

    def call(processor_classes:)
      loop do
        cached_last_event_sequence = last_event_sequence

        data = processor_classes.map do |processor_class|
          processor_lag = cached_last_event_sequence - last_processed_event_sequence(processor_class)

          {
            processor_class_name: processor_class.name,
            processor_lag: processor_lag,
          }
        end

        metrics.call(data)

        sleep sleep_interval
      end
    end

    private

    attr_reader :bookmark_readonly_class, :sequence_stats, :metrics, :database, :sleep_interval

    def last_processed_event_sequence(processor_class)
      bookmark_readonly_class.new(name: processor_class.name).sequence
    end

    def last_event_sequence
      sequence_stats.max_sequence
    end
  end
end
