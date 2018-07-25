require 'dry/struct'

module EventFramework
  class Event < Dry::Struct
    transform_keys(&:to_sym)

    attribute :id, Types::UUID
    attribute :sequence, Types::Strict::Integer
    attribute :aggregate_id, Types::UUID
    attribute :aggregate_sequence, Types::Strict::Integer

    attribute :metadata do
      transform_keys(&:to_sym)

      attribute :account_id, Types::UUID
      attribute :user_id, Types::UUID
      attribute :created_at, Types::JSON::Time
      attribute :correlation_id, Types::UUID.meta(omittable: true)
      attribute :causation_id, Types::UUID.meta(omittable: true)
    end

    attribute :domain_event, DomainEvent

    def type
      domain_event.class
    end
  end
end
