module EventFramework
  module EventStore
    class Source
      autoload :EventTypeDeserializer, 'event_store/source/event_type_deserializer'

      class EventBuilder
        class << self
          def call(row)
            domain_event = EventTypeDeserializer.call(row[:type]).new(row[:body])

            Event.new(
              id: row[:id],
              sequence: row[:sequence],
              aggregate_id: row[:aggregate_id],
              aggregate_sequence: row[:aggregate_sequence],
              metadata: Event::Metadata.new(row[:metadata]),
              domain_event: domain_event,
            )
          end
        end
      end
    end
  end
end
