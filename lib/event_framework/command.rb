require 'dry/struct'
require 'dry/validation'

module EventFramework
  class Command < DomainStruct
    ValidationNotImplementedError = Class.new(Error)

    transform_keys(&:to_sym)

    attribute :aggregate_id, Types::UUID

    class BaseSchema < Dry::Validation::Schema
      configure do
        def uuid?(value)
          !Types::UUID_REGEX.match(value).nil?
        end
      end

      define! do
        required(:aggregate_id).filled(:str?, :uuid?)
      end
    end

    class << self
      def validation_schema(base_schema = BaseSchema, &block)
        @validation_schema = Dry::Validation.Params(base_schema, &block)
      end

      def validate(params)
        raise ValidationNotImplementedError if @validation_schema.nil?

        @validation_schema.call(params)
      end
    end
  end
end
