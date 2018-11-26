module EventFramework
  # An EventProcessor handles processing events from the event source.
  class EventProcessor
    class << self
      def process(*event_classes, &block)
        event_classes.each do |event_class|
          event_handlers.add(event_class, block)
        end
      end

      def event_handlers
        @event_handlers ||= EventHandlerRegistry.new
      end
    end

    def initialize(error_reporter: EventFramework.config.event_processor_error_reporter)
      @error_reporter = error_reporter
    end

    def handled_event_classes
      self.class.event_handlers.handled_event_classes
    end

    def handle_event(event)
      self.class.event_handlers.for(event.domain_event.type).each do |handler|
        instance_exec(event.aggregate_id, event.domain_event, event.metadata, event.id, &handler)
      end
    rescue StandardError => e
      error_reporter.call(e, event)
      raise e
    end

    private

    attr_reader :error_reporter
  end
end
