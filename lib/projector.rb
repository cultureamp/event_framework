module EventFramework
  class Projector < EventProcessor
    def process_events(events)
      database.transaction do
        events.each do |event|
          handle_event(event)
        end
        bookmark.last_processed_event_sequence = events.map(&:sequence).max
      end
    end
  end
end
