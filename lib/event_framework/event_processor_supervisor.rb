require 'forked'

module EventFramework
  # The EventProcessorSupervisor is responsible initializing each event
  # processor and checking out a bookmark for them. It passes them into a
  # Worker and forks.
  class EventProcessorSupervisor
    UNABLE_TO_LOCK_SLEEP_INTERVAL = 1

    class OnForkedError
      def initialize(processor_name)
        @processor_name = processor_name
      end

      def call(error, tries)
        Logger.new(STDOUT).error(msg: error.message, error: error.class.name, tries: tries)
      end

      private

      attr_reader :processor_name
    end

    class << self
      def call(processor_classes)
        new(processor_classes).call
      end
    end

    def initialize(
      processor_classes:,
      process_manager: Forked::ProcessManager.new(logger: Logger.new(STDOUT)),
      bookmark_repository_class: BookmarkRepository,
      projection_database: EventFramework::EventStore.database,
      event_source: EventStore::Source.new
    )
      @processor_classes = processor_classes
      @process_manager = process_manager
      @bookmark_repository_class = bookmark_repository_class
      @projection_database = projection_database
      @event_source = event_source
    end

    def call
      set_process_name

      processor_classes.each do |processor_class|
        process_manager.fork(processor_class.name, on_error: OnForkedError.new(processor_class.name)) do
          # Disconnect from the database to ensure the fork will create it's
          # own connection
          projection_database.disconnect

          logger = Logger.new(STDOUT)

          bookmark = begin
                       bookmark_repository_class.new(
                         name: processor_class.name,
                         database: projection_database,
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
          )
        end
      end

      process_manager.wait_for_shutdown
    end

    private

    attr_reader :processor_classes, :process_manager, :bookmark_repository_class,
                :projection_database, :event_source

    def set_process_name
      Process.setproctitle "event_processor [#{self.class.name}]"
    end
  end
end
