module EventFramework
  # The EventProcessorWorker is responsible for fetching new events from
  # the event source and passing those events to its event processor.
  #
  # It fetches events using the bookmark sequence and handles each event using
  # the event processor. It then updates the bookmark sequence.
  class EventProcessorWorker
    SLEEP_INTERVAL = 0.1

    class << self
      def call(*args)
        new(*args).call
      end
    end

    def initialize(event_processor:, logger:, event_source:, bookmark:)
      @event_processor = event_processor
      @logger = logger
      @event_source = event_source
      @bookmark = bookmark
      @shutdown_requested = false
    end

    def call
      set_process_name
      log('forked')
      listen_for_term_signal
      event_processor.logger = logger if event_processor.respond_to?(:logger=)

      loop do
        break if shutdown_requested

        events = event_source.get_after(bookmark.sequence)

        if events.empty?
          sleep SLEEP_INTERVAL
        else
          log('new_events', event_ids: events.map(&:id))

          events.each do |event|
            log('handle_event.start', event_sequence: event.sequence, event_id: event.id)
            event_processor.handle_event(event)
            log('handle_event.finish', event_sequence: event.sequence, event_id: event.id)

            log('bookmark_update.start', event_sequence: event.sequence, event_id: event.id)
            bookmark.sequence = event.sequence
            log('bookmark_update.finish', event_sequence: event.sequence, event_id: event.id)
          end

          log('processed_up_to', last_processed_event_sequence: bookmark.sequence, last_processed_event_id: events.last.id)
        end
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

    def set_process_name
      Process.setproctitle "event_processor [#{event_processor.class.name}]"
    end

    def log(msg_suffix, params = {})
      logger.info(
        {
          event_processor_class_name: event_processor.class.name,
          msg: "event_processor.worker.#{msg_suffix}",
        }.merge(params),
      )
    end
  end
end
