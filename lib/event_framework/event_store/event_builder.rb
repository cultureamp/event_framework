require 'active_support/core_ext/hash/keys'

module EventFramework
  module EventStore
    class EventBuilder
      class << self
        def call(row)
          domain_event_class = EventTypeDeserializer.call(row[:aggregate_type], row[:event_type])

          row[:body] = row[:body].to_h
          row[:metadata] = row[:metadata].to_h
          row = row.deep_symbolize_keys
          row = domain_event_class.upcast_row(row)

          Event.new(
            id: row[:id],
            sequence: row[:sequence],
            aggregate_id: row[:aggregate_id],
            aggregate_sequence: row[:aggregate_sequence],
            created_at: row[:created_at],
            metadata: Event::Metadata.new(row[:metadata]),
            domain_event: domain_event_class.new(row[:body]),
          )
        end
      end
    end
  end
end
