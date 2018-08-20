require 'dry/struct'
require 'dry/validation'

module EventFramework
  class Command < Dry::Struct
    transform_keys(&:to_sym)

    attribute :aggregate_id, Types::UUID

    class << self
      def validation_schema(&block)
        @validation_schema = Dry::Validation.Params(&block)
      end

      def validate(params)
        @validation_schema.call(params)
      end
    end
  end
end
