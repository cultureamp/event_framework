module EventFramework
  class EventHandlerRegistry
    def initialize
      @event_handlers ||= Hash.new { |h, k| h[k] = [] }
    end

    def add(event_class, block)
      event_handlers[event_class] << block
    end

    def for(event_class)
      event_handlers.fetch(event_class, [])
    end

    def handled_event_classes
      event_handlers.keys
    end

    private

    attr_reader :event_handlers
  end
end
