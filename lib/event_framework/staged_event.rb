require 'dry/struct'

module EventFramework
  class StagedEvent < Dry::Struct
    transform_keys(&:to_sym)

    InvalidDomainEventError = Class.new(Error)

    attribute :aggregate_id, Types::UUID
    attribute :aggregate_sequence, Types::Strict::Integer
    attribute :domain_event, DomainEvent
    attribute :metadata, (Event::Metadata | Event::UnattributedMetadata).optional

    def body
      domain_event.to_h
    end
  end
end
