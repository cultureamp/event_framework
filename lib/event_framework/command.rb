require "dry/struct"
require "dry/validation/version"

module EventFramework
  class Command < DomainStruct
    ValidationNotImplementedError = Class.new(Error)

    attribute :aggregate_id, Types::UUID

    require "dry/validation/contract"

    class BaseSchema < Dry::Validation::Contract
      json do
        # FIXME: This we should remove the permissive UUID regexp and push it into the app
        required(:aggregate_id).filled(Types::UUID)
      end
    end

    class << self
      include Dry::Monads[:result]

      def validation_schema(&block)
        @validation_schema = Class.new(BaseSchema) { json(&block) }.new
      end

      def validate(params)
        raise ValidationNotImplementedError if @validation_schema.nil?

        @validation_schema.call(params)
      end

      def build(params)
        result = validate(params)
        if result.success?
          command = new(result.to_h)
          Success(command)
        else
          Failure([:validation_failed, result.errors])
        end
      end
    end
  end
end
