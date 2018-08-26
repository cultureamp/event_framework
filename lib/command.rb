require 'dry/struct'
require 'dry/validation'

module EventFramework
  class Command < Dry::Struct
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
      def validation_schema(&block)
        @validation_schema = Dry::Validation.Params(BaseSchema, &block)
      end

      def validate(params)
        raise ValidationNotImplementedError if @validation_schema.nil?

        @validation_schema.call(params)
      end
    end
  end
end
