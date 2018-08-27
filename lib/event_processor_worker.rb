module EventFramework
  # The EventProcessorWorker is responsible for fetching new events from
  # the event source and passing those events to its event processor.
  #
  # It checks out a Bookmark for the given event processor and fetches events
  # after that point.
  #
  # The EventProcessor is responsible for updating the bookmark after it's
  # finished processing the events.
  class EventProcessorWorker
    SLEEP_INTERVAL = 1
    UNABLE_TO_LOCK_SLEEP_INTERVAL = 1

    class << self
      def call(*args)
        new(*args).call
      end
    end

    def initialize(
      event_processor_class:,
      logger: Logger.new(STDOUT),
      event_source: EventStore::Source,
      bookmark_repository: BookmarkRepository
    )
      @event_processor_class = event_processor_class
      @logger = logger
      @event_source = event_source
      @bookmark_repository = bookmark_repository
      @shutdown_requested = false
    end

    def call
      logger.info "[#{event_processor_class.name}] forked"
      listen_for_term_signal

      loop do
        break if shutdown_requested

        begin
          events = event_source.get_after(
            bookmark.sequence,
            event_classes: event_processor_class.handled_event_classes,
          )

          if events.empty?
            sleep SLEEP_INTERVAL
          else
            events.each do |event|
              event_processor.handle_event(event)
              bookmark.sequence = event.sequence
            end
          end

          logger.info "[#{event_processor_class.name}] processed up to #{bookmark.sequence.inspect}"
        rescue BookmarkRepository::UnableToCheckoutBookmarkError => e
          logger.info "[#{event_processor_class.name}] #{e.message}"
          sleep UNABLE_TO_LOCK_SLEEP_INTERVAL
        end
      end
    end

    private

    attr_reader :event_processor_class, :logger, :event_source, :bookmark_repository, :shutdown_requested

    def bookmark
      @bookmark ||= bookmark_repository.checkout(name: event_processor_class.name)
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
