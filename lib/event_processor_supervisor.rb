require 'forked'

module EventFramework
  # The EventProcessorSupervisor is responsible for forking each
  # EventProcessorWorker into its own process and then waiting for them to
  # shut down.
  class EventProcessorSupervisor
    class << self
      def call(processor_classes)
        new(processor_classes).call
      end
    end

    def initialize(processor_classes:, process_manager: Forked::ProcessManager.new(logger: Logger.new(STDOUT)))
      @processor_classes = processor_classes
      @process_manager = process_manager
    end

    def call
      processor_classes.each do |processor_class|
        process_manager.fork(processor_class.name) do
          EventProcessorWorker.call(event_processor_class: processor_class)
        end
      end

      process_manager.wait_for_shutdown
    end

    private

    attr_reader :processor_classes, :process_manager
  end
end
