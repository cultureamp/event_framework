module EventFramework
  class Projector < EventProcessor
    def process_events(events)
      events.each do |event|
        self.class.event_handlers.for(event.domain_event.type).each do |handler|
          instance_exec(event.aggregate_id, event.domain_event, event.metadata, &handler)
        end
      end

      bookmark.last_processed_event_sequence = events.map(&:sequence).max
    end
  end
end
