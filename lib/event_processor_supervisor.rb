module EventFramework
  class EventProcessorSupervisor
    SLEEP = 1
    Bookmark = Struct.new(:last_processed_event_sequence)

    # TODO: Locking
    # TODO: Transactions
    class << self
      def call(*args)
        new(*args).call
      end
    end

    def initialize(event_processor_class:, logger: Logger.new(STDOUT))
      @event_processor_class = event_processor_class
      @logger = logger
      @shutdown_requested = false
    end

    def call
      logger.info "[#{event_processor_class.name}] forked"
      listen_for_term_signal

      loop do
        break if shutdown_requested

        # TODO: Limit to event type
        events = EventStore::Source.get_after(bookmark.last_processed_event_sequence)

        if events.empty?
          sleep SLEEP
        else
          # TODO: Add transcation
          # For projectors we can process in batches, for reactors we cannot
          event_processor.process_events(events)
          bookmark.last_processed_event_sequence = events.map(&:sequence).max
        end

        logger.info "[#{event_processor_class.name}] processed up to #{bookmark.last_processed_event_sequence.inspect}"
      end
    end

    private

    attr_reader :event_processor_class, :logger, :shutdown_requested

    # TODO: Find bookmark by event_processor_class
    def bookmark
      @bookmark ||= Bookmark.new(0)
    end

    def event_processor
      @event_processor ||= event_processor_class.new
    end

    def listen_for_term_signal
      Signal.trap(:TERM) { request_shutdown }
    end

    def request_shutdown
      @shutdown_requested = true
    end
  end
end
