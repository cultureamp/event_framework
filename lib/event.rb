require_relative 'types'

module EventFramework
  class Event < Dry::Struct
    class UnpersistedMetadata < Dry::Struct
      transform_keys(&:to_sym)

      attribute :created_at, Types::JSON::Time.meta(omittable: true)
    end

    class Metadata < Dry::Struct
      transform_keys(&:to_sym)

      attribute :created_at, Types::JSON::Time
    end

    transform_keys(&:to_sym)

    attribute :aggregate_id, Types::UUID
    attribute :aggregate_sequence, Types::Integer
    attribute :metadata, (Event::Metadata | Event::UnpersistedMetadata)
  end
end
