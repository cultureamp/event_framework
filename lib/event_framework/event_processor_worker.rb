module EventFramework
  # The EventProcessorWorker is responsible for fetching new events from
  # the event source and passing those events to its event processor.
  #
  # It fetches events using the bookmark sequence and handles each event using
  # the event processor. It then updates the bookmark sequence.
  class EventProcessorWorker
    SLEEP_INTERVAL = 0.1
    DISABLED_SLEEP_INTERVAL = 10

    class << self
      def call(**args, &ready_to_stop)
        new(**args).call(&ready_to_stop)
      end
    end

    def initialize(event_processor:, logger:, event_source:, bookmark:, tracer:)
      @event_processor = event_processor
      @logger = logger
      @event_source = event_source
      @bookmark = bookmark
      @tracer = tracer
    end

    def call(&ready_to_stop)
      set_process_name
      log("forked")
      event_processor.logger = logger if event_processor.respond_to?(:logger=)

      begin
        CA::LaunchDarkly.connect!
      rescue
        # CA::LaunchDarkly may not be available
      end

      loop do
        tracer.trace("event.processor", resource: event_processor.class.name.to_s) do |span|
          # We're in a safe place to stop if we need to.
          ready_to_stop.call

          sequence, disabled = bookmark.next

          if disabled
            sleep DISABLED_SLEEP_INTERVAL
          else
            events = fetch_events(sequence)

            span.set_tag("events.count", events.count)

            if events.empty?
              sleep SLEEP_INTERVAL
            else
              log("new_events", first_event_sequence: events.first.sequence, event_id: events.first.id, count: events.count)

              last_sequence = nil
              events.each do |event|
                tracer.trace("event.processor.handle_event", resource: event.domain_event.class.name) do |span|
                  span.set_tag("event.id", event.id)

                  event_processor.handle_event(event)
                  last_sequence = event.sequence
                  bookmark.sequence = event.sequence
                end
              end

              log("processed_up_to", last_processed_event_sequence: last_sequence, last_processed_event_id: events.last.id)
            end
          end
        end
      end

      begin
        CA::LaunchDarkly.shutdown!
      rescue
        # CA::LaunchDarkly may not be available
      end
    end

    private

    attr_reader :event_processor, :logger, :event_source, :bookmark, :tracer

    def fetch_events(sequence)
      if event_processor.all_handler?
        # If the event processor handles all events we want to get
        # all (unscoped) events.
        event_source.get_after(sequence)
      else
        event_source.get_after(sequence, event_classes: event_processor.handled_event_classes)
      end
    end

    def set_process_name
      Process.setproctitle "event_processor [#{event_processor.class.name}]"
    end

    def log(msg_suffix, params = {})
      logger.info(
        {
          event_processor_class_name: event_processor.class.name,
          msg: "event_processor.worker.#{msg_suffix}"
        }.merge(params)
      )
    end
  end
end
