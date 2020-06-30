require "sequel/core"
require "sequel/extensions/migration"

module EventFramework
  module Tasks
    class DatabaseManager
      DatabaseAlreadyExistsError = Class.new(Error)

      STRIP_VERSION_COMMENTS_REGEX = /
        ^--\sDumped\sfrom\sdatabase\sversion.*$\n
        ^--\sDumped\sby\spg_dump\sversion.*$\n
        ^\n
      /x

      attr_reader :connection

      def initialize(connection)
        @connection = connection
      end

      def create
        Sequel.connect(root_database_uri.to_s) do |db|
          db.execute "CREATE DATABASE #{db_name}"
        end
      rescue Sequel::DatabaseError => e
        if e.cause.is_a?(PG::DuplicateDatabase)
          raise DatabaseAlreadyExistsError
        else
          raise
        end
      end

      def drop
        Sequel.connect(root_database_uri.to_s) do |db|
          db.execute "DROP DATABASE IF EXISTS #{db_name}"
        end
      end

      def migrate(migrations_path:, target_version:)
        Sequel::Migrator.run(connection.connection, migrations_path, target: target_version)
      end

      def dump_schema(schema_path:)
        retval = system(
          "pg_dump",
          "--schema-only",
          "--no-owner",
          "--no-privileges",
          "--file",
          schema_path.to_s,
          connection.uri.to_s
        )

        return unless retval

        # `pg_dump` inlcludes comments denoting version numbers of the database /
        # tool used to create the dump. We have no guaranteed version of
        # postgres on developer machines, so strip out this information to
        # avoid low-value noise when comitting the schema
        contents = File.read(schema_path)
        contents.gsub!(STRIP_VERSION_COMMENTS_REGEX, "")

        File.open(schema_path, "w") { |file| file.puts contents }

        schema_path
      end

      private

      def root_database_uri
        connection.uri.tap { |u| u.path = "/postgres" }
      end

      def db_name
        File.basename(connection.uri.path)
      end
    end
  end
end
