module EventFramework
  # An EventProcessor handles processing events from the event source.
  #
  # Subclasses should override the process_events method and ensure they update
  # the bookmark sequence after processing events.
  #
  # The EventProcessor is a base class for Projectors and Reactors but can be
  # used by any subclass that needs to be able to handle events.
  class EventProcessor
    class << self
      extend Forwardable

      def_delegators :event_handlers, :handled_event_classes

      def process(*event_classes, &block)
        event_classes.each do |event_class|
          event_handlers.add(event_class, block)
        end
      end

      def event_handlers
        @event_handlers ||= EventHandlerRegistry.new
      end
    end

    def process_events(_events)
      raise NotImplementedError
    end

    private

    def handle_event(event)
      self.class.event_handlers.for(event.domain_event.type).each do |handler|
        instance_exec(event.aggregate_id, event.domain_event, event.metadata, &handler)
      end
    end

    def bookmark
      @bookmark ||= BookmarkRepository.checkout(name: self.class.name)
    end

    def database
      EventStore.database
    end
  end
end
