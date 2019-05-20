require 'dry/struct'

module EventFramework
  class Event < DomainStruct
    attribute :id, Types::UUID
    attribute :sequence, Types::Strict::Integer
    attribute :aggregate_id, Types::UUID
    attribute :aggregate_sequence, Types::Strict::Integer
    attribute :created_at, Types::JSON::Time

    attribute :metadata, DomainStruct do
      attribute :account_id, Types::UUID
      attribute :user_id, Types::UUID
      attribute :correlation_id, Types::UUID.meta(omittable: true)
      attribute :causation_id, Types::UUID.meta(omittable: true)
      # The "bypass_mongo_projection" field is being replaced with "migrated".
      attribute :migrated, Types::Bool.meta(omittable: true)
      attribute :bypass_mongo_projection, Types::Bool.meta(omittable: true)
    end

    attribute :domain_event, DomainEvent

    def type
      domain_event.class
    end
  end
end
