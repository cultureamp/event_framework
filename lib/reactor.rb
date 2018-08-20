module EventFramework
  class Reactor < EventProcessor
    def process_events(events)
      events.each do |event|
        database.transaction do
          handle_event(event)
          bookmark.sequence = event.sequence
        end
      end
    end
  end
end
