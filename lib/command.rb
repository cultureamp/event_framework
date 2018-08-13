require 'dry/struct'
require 'dry/validation'

module EventFramework
  class Command < Dry::Struct
    transform_keys(&:to_sym)

    class << self
      def validation_schema(&block)
        @validation_schema = Dry::Validation.Params(&block)
      end

      def validate(params)
        @validation_schema.call(params)
      end

      def schema(*args)
        raise 'Define validation schema using `validation_schema`.' if block_given?
        super
      end
    end
  end
end
