require_relative '../transformations'

module EventFramework
  module EventStore
    class EventBuilder
      def initialize(event_type_resolver:)
        @event_type_resolver = event_type_resolver
      end

      def call(row)
        domain_event_class = event_type_resolver.deserialize(row[:aggregate_type], row[:event_type])

        # The body and metadata fields are returned from the database as
        # Sequel::Postgres::JSONBHash so we want to turn them into standard
        # Ruby hashes.
        row[:body] = row[:body].to_h
        row[:metadata] = row[:metadata].to_h

        row[:metadata] = upcast_metadata(row[:metadata].to_h)
        row = Transformations[:deep_symbolize_keys].call(row)
        row = domain_event_class.upcast_row(row)

        Event.new(
          id: row[:id],
          sequence: row[:sequence],
          aggregate_id: row[:aggregate_id],
          aggregate_sequence: row[:aggregate_sequence],
          created_at: row[:created_at],
          metadata: build_metadata(row[:metadata]),
          domain_event: domain_event_class.new(row[:body]),
        )
      end

      private

      attr_reader :event_type_resolver

      def upcast_metadata(metadata)
        metadata[:metadata_type] ||= "attributed"
        metadata
      end

      def build_metadata(metadata)
        case metadata[:metadata_type]
        when "attributed"
          Event::Metadata.new(metadata)
        when "unattributed"
          Event::UnattributedMetadata.new(metadata)
        else
          raise "unknown metadata_type: #{metadata[:metadata_type].inspect}"
        end
      end
    end
  end
end
