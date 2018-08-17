module EventFramework
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

    def bookmark
      @bookmark ||= BookmarkRepository.get_lock(name: self.class.name)
    end
  end
end
