module EventFramework
  class ParameterStore
    class << self
      def db_hostname
        @_db_hostname ||= ssm_client.get_parameters_by_path(
          path: "/#{farm_name}/murmur/event_store/db/hostname",
          with_decryption: false,
        )
      end

      def db_name
        @_db_name ||= ssm_client.get_parameters_by_path(
          path: "/#{aws_account}/murmur/event_store/db/name",
          with_decryption: false,
        )
      end

      def db_username
        @_db_username ||= ssm_client.get_parameters_by_path(
          path: "/#{aws_account}/murmur/event_store/db/username",
          with_decryption: false,
        )
      end

      def db_password
        @_db_password ||= ssm_client.get_parameters_by_path(
          path: "/#{aws_account}/murmur/event_store/db/password",
          with_decryption: true,
        )
      end

      def database_url
        "postgres://#{db_username}:#{db_password}@#{db_hostname}/#{db_name}"
      end

      private

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
                          when 'preprod', 'staging'
                            'staging'
                          else
                            'development'
                          end
      end
    end
  end
end

EventFramework.configure do |config|
  config.database_url = EventFramework::ParameterStore.database_url
end
