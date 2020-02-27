require 'dry/struct'

module EventFramework
  class Event < DomainStruct
    class BaseMetadata < DomainStruct
      attribute :account_id, Types::UUID
      attribute :correlation_id, Types::UUID.meta(omittable: true)
      attribute :causation_id, Types::UUID.meta(omittable: true)
      attribute :migrated, Types::Bool.meta(omittable: true)
    end

    class Metadata < BaseMetadata
      attribute :user_id, Types::UUID
      attribute :metadata_type, Types.Constant(:attributed).default(:attributed)
    end

    class UnattributedMetadata < BaseMetadata
      attribute :metadata_type, Types.Constant(:unattributed).default(:unattributed)
    end

    attribute :id, Types::UUID
    attribute :sequence, Types::Strict::Integer
    attribute :aggregate_id, Types::UUID
    attribute :aggregate_sequence, Types::Strict::Integer
    attribute :created_at, Types::JSON::Time

    attribute :metadata, Metadata | UnattributedMetadata

    attribute :domain_event, DomainEvent

    def type
      domain_event.class
    end
  end
end
