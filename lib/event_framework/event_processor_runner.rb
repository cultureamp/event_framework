require "event_framework/exponential_backoff"
require "event_framework/with_graceful_shutdown"

module EventFramework
  # The EventProcessorRunner is responsible for initializing a single event
  # processor, checking out a bookmark for it then starting a worker.
  class EventProcessorRunner
    UNABLE_TO_LOCK_SLEEP_INTERVAL = 1

    class OnError
      def initialize(logger)
        @logger = logger
      end

      def call(error, tries)
        @logger.error(msg: error.message, error: error.class.name, tries: tries)
      end
    end

    def initialize(
      processor_class:,
      domain_context:,
      tracer: EventFramework::Tracer::NullTracer.new
    )
      @processor_class = processor_class
      @domain_context = domain_context
      @tracer = tracer
    end

    def call
      set_process_name

      event_processor = processor_class.new
      logger = Logger.new(STDOUT)
      bookmark = checkout_bookmark
      event_source = domain_context.container.resolve("event_store.source")

      WithGracefulShutdown.run(logger: logger) do |ready_to_stop|
        ExponentialBackoff.new(logger: logger, on_error: OnError.new(logger)).run(ready_to_stop) do
          EventProcessorWorker.call(
            event_processor: event_processor,
            logger: logger,
            bookmark: bookmark,
            event_source: event_source,
            tracer: @tracer,
            &ready_to_stop
          )
        end
      end
    end

    private

    attr_reader :processor_class, :domain_context

    def checkout_bookmark
      projection_database = domain_context.database(:projections)
      BookmarkRepository.new(
        name: processor_class.name,
        database: projection_database
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
