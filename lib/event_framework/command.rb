require 'dry/struct'
require 'dry/validation'

module EventFramework
  class Command < DomainStruct
    ValidationNotImplementedError = Class.new(Error)

    attribute :aggregate_id, Types::UUID

    class BaseSchema < Dry::Validation::Schema
      configure do
        config.messages_file = EventFramework.root.join('config', 'dry-validation_messages.yml')

        def uuid?(value)
          !Types::UUID_REGEX.match(value).nil?
        end

        def utc?(value)
          value.zone == '+00:00'
        end
      end

      define! do
        required(:aggregate_id) { str? & uuid? }
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
