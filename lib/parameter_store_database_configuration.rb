require 'aws-sdk-core'
require 'aws-sdk-ssm'

module EventFramework
  # Parameters are stored in the format /murmur/event_store/$FARM/database_url
  class ParameterStoreDatabaseConfiguration
    PARAMETER_PREFIX = '/murmur/event_store'

    def initialize(farm_name)
      @farm_name = farm_name
    end

    def database_url
      ssm_param.value
    end

    private

    def ssm_client
      @_ssm_client ||= Aws::SSM::Client.new(
        credentials: Aws::InstanceProfileCredentials.new,
        region: 'us-west-2',
      )
    end

    def ssm_param
      @_ssm_params ||= begin
        response = ssm_client.get_parameter(
          name: parameter_path,
          with_decryption: true,
        )

        response.parameter
      end
    end

    def parameter_path
      [PARAMETER_PREFIX, @farm_name, 'database_url'].join('/')
    end
  end
end
