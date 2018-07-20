require 'types'

module EventFramework
  class Event < Dry::Struct
    transform_keys(&:to_sym)

    attribute :aggregate_id, Types::UUID
    attribute :aggregate_sequence_id, Types::Integer
    attribute :metadata, Types::Hash
  end
end
