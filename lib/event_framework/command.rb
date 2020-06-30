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
          !Types::UUID_REGEX.match(value.to_s).nil?
        end

        def utc?(value)
          case value
          when Time
            value.utc?
          when DateTime
            value.zone == '+00:00'
          else
            false
          end
        end
      end

      define! do
        required(:aggregate_id) { uuid? }
      end
    end

    class << self
      include Dry::Monads[:result]

      def validation_schema(&block)
        @validation_schema = Dry::Validation.Params(BaseSchema, &block)
      end

      def validate(params)
        raise ValidationNotImplementedError if @validation_schema.nil?

        @validation_schema.call(params)
      end

      def build(params)
        result = validate(params)
        if result.success?
          command = new(result.output)
          Success(command)
        else
          Failure([:validation_failed, result.errors])
        end
      end
    end
  end
end
