require 'dry/struct'

module EventFramework
  class StagedEvent < Dry::Struct
    transform_keys(&:to_sym)

    attribute :aggregate_id, Types::UUID
    attribute :aggregate_sequence, Types::Strict::Integer
    attribute :domain_event, DomainEvent

    attribute :metadata do
      transform_keys(&:to_sym)

      attribute :account_id, Types::UUID
      attribute :user_id, Types::UUID
      attribute :correlation_id, Types::UUID
      attribute :causation_id, Types::UUID.meta(omittable: true)
    end

    def type
      event_name, aggregate_name = domain_event.class.name.split('::').reverse

      [aggregate_name, event_name].compact.join('::')
    end

    def body
      domain_event.to_h
    end
  end
end
