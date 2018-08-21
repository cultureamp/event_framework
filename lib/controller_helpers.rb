require 'dry/configurable'

module EventFramework
  module ControllerHelpers
    extend Dry::Configurable

    MissingRequestIdError = Class.new(StandardError)

    setting :metadata_class
    setting :user_id_resolver, -> {}
    setting :account_id_resolver, -> {}
    setting :request_id_resolver, -> {}

    module Buildable
      def build_handler(handler_class)
        config = EventFramework::ControllerHelpers.config

        metadata = config.metadata_class.new(
          user_id: instance_exec(&config.user_id_resolver),
          account_id: instance_exec(&config.account_id_resolver),
          correlation_id: instance_exec(&config.request_id_resolver),
        )

        raise MissingRequestIdError if metadata.correlation_id.nil?

        handler_class.new(metadata: metadata)
      end
    end
  end
end
