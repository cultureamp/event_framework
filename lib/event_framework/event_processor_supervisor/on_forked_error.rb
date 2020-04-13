module EventFramework
  class EventProcessorSupervisor
    class OnForkedError
      def initialize(processor_name)
        @processor_name = processor_name
      end

      def call(error, tries)
        Logger.new(STDOUT).error(
          msg: error.message,
          event_processor: processor_name,
          error: error.class.name,
          tries: tries,
        )
      end

      private

      attr_reader :processor_name
    end
  end
end
