require_relative '../transformations'

module EventFramework
  module EventStore
    class EventBuilder
      def initialize(event_type_resolver:)
        @event_type_resolver = event_type_resolver
      end

      def call(row)
        domain_event_class = event_type_resolver.deserialize(row[:aggregate_type], row[:event_type])

        row[:body] = row[:body].to_h
        row[:metadata] = row[:metadata].to_h
        row = Transformations[:deep_symbolize_keys].call(row)
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

      private

      attr_reader :event_type_resolver
    end
  end
end
