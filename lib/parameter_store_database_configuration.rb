require 'aws-sdk-core'
require 'aws-sdk-ssm'

module EventFramework
  class ParameterStoreDatabaseConfiguration
    PARAMETER_PREFIX = '/murmur/event_store/db'

    def initialize(farm_name)
      @farm_name = farm_name
    end

    def database_url
      @_database_url ||= URI::Generic.build(
        scheme: 'postgres',
        userinfo: db_userinfo,
        host: db_hostname,
        path: "/#{db_name}",
      )
    end

    private

    def db_userinfo
      [db_username, db_password].join(':')
    end

    # The development account has many farms, each one with its own
    # database instance; the CloudFormation stack automatically generates a
    # hostname parameter in SSM, and suffixes it with the relevant farm name.
    def db_hostname
      ssm_params["#{PARAMETER_PREFIX}/hostname/#{@farm_name}"]
    end

    def db_name
      ssm_params["#{PARAMETER_PREFIX}/name"]
    end

    def db_username
      ssm_params["#{PARAMETER_PREFIX}/username"]
    end

    def db_password
      ssm_params["#{PARAMETER_PREFIX}/password"]
    end

    def ssm_client
      @_ssm_client ||= Aws::SSM::Client.new(
        credentials: Aws::InstanceProfileCredentials.new,
        region: 'us-west-2',
      )
    end

    def ssm_params
      @_ssm_params ||= begin
        response = ssm_client.get_parameters_by_path(
          path: PARAMETER_PREFIX,
          recursive: true,
          with_decryption: true,
        )

        # get_parameters_by_path returns an array of Aws::SSM::Types::GetParametersByPathResult,
        # which we then reduce into a hash.
        response.parameters.each.with_object({}) do |parameter, hash|
          hash[parameter.name] = parameter.value
        end
      end
    end
  end
end
