module EventFramework
  # The EventProcessorWorker is responsible for fetching new events from
  # the event source and passing those events to its event processor.
  #
  # It fetches events using the bookmark sequence and handles each event using
  # the event processor. It then updates the bookmark sequence.
  class EventProcessorWorker
    SLEEP_INTERVAL = 1

    class << self
      def call(*args)
        new(*args).call
      end
    end

    def initialize(event_processor:, logger:, event_source: EventStore::Source, bookmark:)
      @event_processor = event_processor
      @logger = logger
      @event_source = event_source
      @bookmark = bookmark
      @shutdown_requested = false
    end

    def call
      logger.info "[#{event_processor.class.name}] forked"
      listen_for_term_signal

      loop do
        break if shutdown_requested

        events = event_source.get_after(
          bookmark.sequence,
          event_classes: event_processor.class.handled_event_classes,
        )

        if events.empty?
          sleep SLEEP_INTERVAL
        else
          events.each do |event|
            event_processor.handle_event(event)
            bookmark.sequence = event.sequence
          end
        end

        logger.info "[#{event_processor.class.name}] processed up to #{bookmark.sequence.inspect}"
      end
    end

    private

    attr_reader :event_processor, :logger, :event_source, :bookmark, :shutdown_requested

    def listen_for_term_signal
      Signal.trap(:TERM) { request_shutdown }
    end

    def request_shutdown
      @shutdown_requested = true
    end
  end
end
