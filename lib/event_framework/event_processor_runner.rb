require 'forked'

module EventFramework
  # The EventProcessorRunner is responsible initializing a single event
  # processor and checking out a bookmark for it then starting a worker.
  class EventProcessorRunner
    UNABLE_TO_LOCK_SLEEP_INTERVAL = 1

    def initialize(processor_class:, domain_context:)
      @processor_class = processor_class
      @domain_context = domain_context
    end

    def call
      set_process_name

      event_processor = processor_class.new
      logger = Logger.new(STDOUT)
      bookmark = checkout_bookmark
      event_source = domain_context.container.resolve("event_store.source")

      EventProcessorWorker.call(
        event_processor: event_processor,
        logger: logger,
        bookmark: bookmark,
        event_source: event_source,
      )
    end

    private

    attr_reader :processor_class, :domain_context

    def checkout_bookmark
      projection_database = domain_context.database(:projections)
      BookmarkRepository.new(
        name: processor_class.name,
        database: projection_database,
      ).checkout
    rescue BookmarkRepository::UnableToCheckoutBookmarkError => e
      logger.info(processor_class_name: processor_class.name, msg: e.message)
      sleep UNABLE_TO_LOCK_SLEEP_INTERVAL
      retry
    end

    def set_process_name
      Process.setproctitle "event_processor [#{self.class.name}]"
    end
  end
end
