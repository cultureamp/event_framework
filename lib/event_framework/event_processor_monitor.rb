module EventFramework
  class EventProcessorMonitor
    # We store metric points at the 1 second resolution, but we'd prefer if you
    # only submitted points every 15 seconds. Any metrics with fractions of a
    # second timestamps gets rounded to the nearest second, and if any points
    # have the same timestamp, the latest point overwrites the previous ones.
    #
    # https://docs.datadoghq.com/api/?lang=ruby#metrics
    SLEEP_INTERVAL = 15

    def initialize(
      sequence_stats_class: EventStore::SequenceStats,
      metrics:,
      bookmark_database:,
      sequence_stats_database:,
      sleep_interval: SLEEP_INTERVAL
    )
      @sequence_stats_class = sequence_stats_class
      @metrics = metrics
      @bookmark_database = bookmark_database
      @sequence_stats_database = sequence_stats_database
      @sleep_interval = sleep_interval
      @readonly_bookmarks = {}
      @sequence_stats = sequence_stats_class.new(database: sequence_stats_database)
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

    attr_reader :sequence_stats_class, :sequence_stats, :metrics, :bookmark_database, :sequence_stats_database, :sleep_interval

    def last_processed_event_sequence(processor_class)
      readonly_bookmark(processor_class.name).sequence
    end

    def last_event_sequence
      sequence_stats.max_sequence
    end

    def readonly_bookmark(processor_class_name)
      @readonly_bookmarks[processor_class_name] ||= begin
        BookmarkRepository.new(name: processor_class_name, database: bookmark_database).readonly_bookmark
      end
    end
  end
end
