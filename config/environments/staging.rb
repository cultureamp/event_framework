require 'aws-sdk-core'
require 'aws-sdk-ssm'

module EventFramework
  class ParameterStore
    def database_url
      "postgres://#{db_username}:#{db_password}@#{db_hostname}/#{db_name}"
    end

    private

    def db_hostname
      @_db_hostname ||= begin
        response = ssm_client.get_parameter(
          name: "/#{farm_name}/murmur/event_store/db/hostname",
          with_decryption: false,
        )
        response&.parameter&.value
      end
    end

    def db_name
      @_db_name ||= begin
        response = ssm_client.get_parameter(
          name: "/#{aws_account}/murmur/event_store/db/name",
          with_decryption: false,
        )
        response&.parameter&.value
      end
    end

    def db_username
      @_db_username ||= begin
        response = ssm_client.get_parameter(
          name: "/#{aws_account}/murmur/event_store/db/username",
          with_decryption: false,
        )
        response&.parameter&.value
      end
    end

    def db_password
      @_db_password ||= begin
        response = ssm_client.get_parameter(
          name: "/#{aws_account}/murmur/event_store/db/password",
          with_decryption: true,
        )
        response&.parameter&.value
      end
    end

    def ssm_client
      @_ssm_client ||= Aws::SSM::Client.new(
        credentials: Aws::InstanceProfileCredentials.new,
        region: 'us-west-2',
      )
    end

    def farm_name
      ENV.fetch('STAGING_HOSTNAME', '')
    end

    def aws_account
      @_aws_account ||= case farm_name
                        when 'preprod', 'staging', 'grumpycat'
                          'staging'
                        else
                          'development'
                        end
    end
  end
end

EventFramework.configure do |config|
  config.database_url = EventFramework::ParameterStore.new.database_url
end
