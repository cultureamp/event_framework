require "forked"
require "event_framework/event_processor_supervisor/on_forked_error"
require "event_framework/exponential_backoff"

module EventFramework
  # The EventProcessorSupervisor is responsible initializing each event
  # processor and checking out a bookmark for them. It passes them into a
  # Worker and forks.
  class EventProcessorSupervisor
    UNABLE_TO_LOCK_SLEEP_INTERVAL = 1

    def initialize(
      processor_classes:,
      projection_database:, event_source:,
      tracer: EventFramework::Tracer::NullTracer.new,
      process_manager: Forked::ProcessManager.new(logger: Logger.new(STDOUT)),
      bookmark_repository_class: BookmarkRepository
    )
      @processor_classes = processor_classes
      @process_manager = process_manager
      @bookmark_repository_class = bookmark_repository_class
      @projection_database = projection_database
      @event_source = event_source
      @tracer = tracer
    end

    def call
      set_process_name

      processor_classes.each do |processor_class|
        fork_args = {
          retry_strategy: ExponentialBackoff,
          on_error: OnForkedError.new(processor_class.name)
        }

        process_manager.fork(processor_class.name, fork_args) do |ready_to_stop|
          # Disconnect from the database to ensure the fork will create it's
          # own connection
          projection_database.disconnect

          logger = Logger.new(STDOUT)

          bookmark = begin
            bookmark_repository_class.new(
              name: processor_class.name,
              database: projection_database
            ).checkout
          rescue BookmarkRepository::UnableToCheckoutBookmarkError => e
            logger.info(processor_class_name: processor_class.name, msg: e.message)
            sleep UNABLE_TO_LOCK_SLEEP_INTERVAL
            retry
          end

          event_processor = processor_class.new

          EventProcessorWorker.call(
            event_processor: event_processor,
            logger: logger,
            bookmark: bookmark,
            event_source: event_source,
            tracer: tracer,
            &ready_to_stop
          )
        end
      end

      process_manager.wait_for_shutdown
    end

    private

    attr_reader :processor_classes, :process_manager, :bookmark_repository_class,
      :projection_database, :event_source, :tracer

    def set_process_name
      Process.setproctitle "event_processor [#{self.class.name}]"
    end
  end
end
