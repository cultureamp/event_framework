require 'dry/configurable'

module EventFramework
  module ControllerHelpers
    extend Dry::Configurable

    setting :metadata_class
    setting :user_id_resolver, -> {}
    setting :account_id_resolver, -> {}
    setting :request_id_resolver, -> {}

    module MetadataHelper
      MissingRequestIdError = Class.new(StandardError)

      def build_metadata
        config = EventFramework::ControllerHelpers.config

        metadata_args = {
          user_id: instance_exec(&config.user_id_resolver),
          account_id: instance_exec(&config.account_id_resolver),
          correlation_id: instance_exec(&config.request_id_resolver),
        }

        config.metadata_class.new(**metadata_args).tap do |m|
          raise MissingRequestIdError if m.correlation_id.nil?
        end
      end
    end

    module CommandHelper
      def validate_params_for_command(params, command_class)
        command_class.validate(params)
      end
    end
  end
end
