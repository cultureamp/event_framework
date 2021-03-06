module EventFramework
  class EventHandlerRegistry
    def initialize
      @event_handlers = Hash.new { |h, k| h[k] = [] }
    end

    def add(event_class, block)
      event_handlers[event_class] << block
    end

    def add_all_handler(block)
      @all_handler = block
    end

    def for(event_class)
      event_handlers.fetch(event_class, []) + all_handler
    end

    def handled_event_classes
      if all_handler?
        raise "handled_event_classes should not be used when event processor handles all events"
      else
        event_handlers.keys
      end
    end

    def all_handler?
      !all_handler.empty?
    end

    private

    attr_reader :event_handlers

    def all_handler
      [@all_handler].compact
    end
  end
end
