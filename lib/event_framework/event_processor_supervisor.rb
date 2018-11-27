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
        Logger.new(STDOUT).error("[#{processor_name}] error: #{error.inspect}, tries: #{tries}")
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
      bookmark_repository_class: BookmarkRepository
    )
      @processor_classes = processor_classes
      @process_manager = process_manager
      @bookmark_repository_class = bookmark_repository_class
    end

    def call
      set_process_name

      processor_classes.each do |processor_class|
        process_manager.fork(processor_class.name, on_error: OnForkedError.new(processor_class.name)) do
          begin
            logger = Logger.new(STDOUT)
            bookmark = bookmark_repository_class.new(name: processor_class.name).checkout
            event_processor = processor_class.new

            EventProcessorWorker.call(event_processor: event_processor, logger: logger, bookmark: bookmark)
          rescue BookmarkRepository::UnableToCheckoutBookmarkError => e
            logger.info "[#{processor_class.name}] #{e.message}"
            sleep UNABLE_TO_LOCK_SLEEP_INTERVAL
          end
        end
      end

      process_manager.wait_for_shutdown
    end

    private

    attr_reader :processor_classes, :process_manager, :bookmark_repository_class

    def set_process_name
      Process.setproctitle "event_processor [#{self.class.name}]"
    end
  end
end
