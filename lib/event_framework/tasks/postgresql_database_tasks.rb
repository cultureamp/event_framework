module EventFramework
  module Tasks
    class PostgreSQLDatabaseTasks
      DEFAULT_ENCODING = ENV['CHARSET'] || 'utf8'
      ON_ERROR_STOP_1 = 'ON_ERROR_STOP=1'.freeze
      SQL_COMMENT_BEGIN = '--'.freeze

      attr_reader :database_url

      def initialize(database_url)
        @database_url = database_url
      end

      def create
        require 'sequel/core'

        Sequel.connect(root_database_uri.to_s) do |db|
          db.execute "CREATE DATABASE #{db_name}"
        end
      rescue Sequel::DatabaseError => error
        if error.cause.is_a?(PG::DuplicateDatabase)
          raise DatabaseAlreadyExists
        else
          raise
        end
      end

      def drop
        require 'sequel/core'

        Sequel.connect(root_database_uri.to_s) do |db|
          db.execute "DROP DATABASE IF EXISTS #{db_name}"
        end
      end

      def migrate(migrations_path:, target_version:)
        require 'sequel/core'

        Sequel.connect(database_url) do |db|
          Sequel::Migrator.run(db, migrations_path, target: target_version)
        end
      end

      def create_migration(migrations_path:, migration_name: 'migration')
        require 'sequel/core'

        Sequel.extension :inflector

        timestamp_prefix = Time.now.utc.strftime('%Y%m%d%H%M%S')
        file_name = "#{timestamp_prefix}_#{migration_name.underscore}.rb"

        File.open("#{migrations_path}/#{file_name}", 'w') do |f|
          f << <<~MIGRATION
            Sequel.migration do
              up do
              end

              down do
              end
            end
          MIGRATION
        end
        $stdout.puts "Created migration #{file_name}"
      end

      def check_target_version(target_version)
        require 'sequel/extensions/migration'

        if target_version && !(Sequel::Migrator::MIGRATION_FILE_PATTERN.match?(ENV['VERSION']) || /\A\d+\z/.match?(ENV['VERSION']))
          raise "Invalid format of target version: `VERSION=#{ENV['VERSION']}`"
        end
      end

      private

      def database_uri
        URI.parse(database_url)
      end

      def root_database_uri
        database_uri.tap { |u| u.path = '/postgres' }
      end

      def db_name
        File.basename(database_uri.path)
      end
    end
  end
end
