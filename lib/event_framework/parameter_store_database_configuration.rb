require 'aws-sdk-core'
require 'aws-sdk-ssm'

# TODO: Delete after configuration re-factor is complete
module EventFramework
  # Parameters are stored in the format /murmur/event_store/$FARM/database_url
  class ParameterStoreDatabaseConfiguration
    PARAMETER_PREFIX = '/murmur/event_store'

    def initialize(farm_name)
      @farm_name = farm_name
    end

    def database_url
      ssm_client
        .get_parameter(name: parameter_path, with_decryption: true)
        .parameter
        .value
    rescue Aws::SSM::Errors::AccessDeniedException, Aws::SSM::Errors::ParameterNotFound
      # If the instance can't connect to ParameterStore or the parameter, return nil;
      # this will trigger a NotImplemented error if EventStore tries to connect,
      # which we can handle gracefully up-stream.
      nil
    end

    private

    def ssm_client
      @_ssm_client ||= Aws::SSM::Client.new(
        region: 'us-west-2',
      )
    end

    def parameter_path
      [PARAMETER_PREFIX, @farm_name, 'database_url'].join('/')
    end
  end
end
