require "dry/struct"

module EventFramework
  class Event < DomainStruct
    class BaseMetadata < DomainStruct
      attribute :account_id, Types::UUID
      attribute :correlation_id, Types::UUID.meta(omittable: true)
      attribute :causation_id, Types::UUID.meta(omittable: true)
      attribute :migrated, Types::Bool.meta(omittable: true)

      def unattributed?
        metadata_type == "unattributed"
      end
    end

    class Metadata < BaseMetadata
      attribute :user_id, Types::UUID
      attribute :metadata_type, Types.Value("attributed").default("attributed".freeze)

      def self.new_with_fallback(fallback_class:, **args)
        new(args)
      rescue Dry::Struct::Error
        extra_attributes = attribute_names - fallback_class.attribute_names
        args = args.reject { |k, _v| extra_attributes.include?(k) }
        fallback_class.new(args)
      end
    end

    class UnattributedMetadata < BaseMetadata
      attribute :metadata_type, Types.Value("unattributed").default("unattributed".freeze)
    end

    class SystemMetadata < BaseMetadata
      attribute :metadata_type, Types.Value("system").default("system".freeze)
    end

    attribute :id, Types::UUID
    attribute :sequence, Types::Strict::Integer
    attribute :aggregate_id, Types::UUID
    attribute :aggregate_sequence, Types::Strict::Integer
    attribute :created_at, Types::JSON::Time

    attribute :metadata, Metadata | UnattributedMetadata | SystemMetadata

    attribute :domain_event, DomainEvent

    def type
      domain_event.class
    end
  end
end
