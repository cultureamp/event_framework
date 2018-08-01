require 'dry/struct'

module EventFramework
  class StagedEvent < Dry::Struct
    transform_keys(&:to_sym)

    InvalidDomainEventError = Class.new(Error)

    EventTypeDescription = Struct.new(:event_type, :aggregate_type)

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

    def aggregate_type
      raise InvalidDomainEventError if type_description.aggregate_type.nil?

      type_description.aggregate_type
    end

    def event_type
      type_description.event_type
    end

    def body
      domain_event.to_h
    end

    private

    def type_description
      @type_description ||= EventTypeDescription.new(*domain_event.class.name.split('::').reverse.slice(0, 2))
    end
  end
end
