module EventFramework
  # A Reactor is a type of EventProcessor.
  #
  # It handles events passed to it, typically by a EventProcessorSupervisor.
  #
  # A Reactor may have external side effects (e.g. sending emails) and may
  # sink events to record the result of those side effects.
  #
  # Because of the external side effects we want to have a separate transaction
  # for each event we process to limit the chance of duplicating external side
  # effects.
  #
  # NOTE: The emitting of events has not been built yet.
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
