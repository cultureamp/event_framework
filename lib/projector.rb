module EventFramework
  # A Projector is a type of EventProcessor.
  #
  # It handles events passed to it, typically by a EventProcessorSupervisor.
  #
  # We can wrap the processing of a batch of events inside a transaction to
  # speed up our database operations.
  class Projector < EventProcessor
    def process_events(events)
      database.transaction do
        events.each do |event|
          handle_event(event)
        end
        bookmark.sequence = events.map(&:sequence).max
      end
    end
  end
end
