require 'dry/configurable'

module EventFramework
  module CommandHandlerBuilder
    extend Dry::Configurable

    setting :metadata_class
    setting :user_id_resolver, -> {}
    setting :account_id_resolver, -> {}
    setting :request_id_resolver, -> {}

    module Mixin
      def build_handler(handler_class)
        # just sugar, that's all.
        c = EventFramework::CommandHandlerBuilder.config

        metadata = c.metadata_class.new(
          user_id: instance_exec(&c.user_id_resolver),
          account_id: instance_exec(&c.account_id_resolver),
          correlation_id: instance_exec(&c.request_id_resolver),
        )

        raise "no request_id" if metadata.correlation_id.nil?

        handler_class.new(metadata: metadata)
      end
    end
  end
end
