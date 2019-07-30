require 'dry/inflector'
require 'thor'

module EventFramework
  module Tasks
    class Runner < Thor
      include Thor::Actions

      def self.exit_on_failure?
        true
      end

      register Tasks::Generators::MigrationGenerator, "generate:migration", "generate:migration CONTEXT DATABASE_NAME", "Generates an empty migration"

      desc "create_database CONTEXT DATABASE_NAME", "Creates the PostgreSQL database for the indicated context/database"
      def create_database(context_name, database_name)
        return unless database_managed?(context_name, database_name)

        connection = context_module(context_name).database(database_name.to_sym)

        DatabaseManager.new(connection).create

        say_with_db context_name, database_name, "created"
      rescue EventFramework::BoundedContext::NoSuchDatabaseRegisteredError
        say_with_db context_name, database_name, "unknown database; has it been registered?", :red
      rescue DatabaseManager::DatabaseAlreadyExistsError
        say_with_db context_name, database_name, "already exists, skipping", :yellow
      rescue EventFramework::DatabaseConnection::MissingConnectionURLError
        say_with_db context_name, database_name, "no URL configured; skipping", :yellow
      end

      desc "drop_database CONTEXT DATABASE_NAME", "Drops the PostgreSQL database for the indicated context/database"
      def drop_database(context_name, database_name)
        return unless database_managed?(context_name, database_name)

        connection = context_module(context_name).database(database_name.to_sym)

        DatabaseManager.new(connection).drop
      rescue EventFramework::DatabaseConnection::MissingConnectionURLError
        say_with_db context_name, database_name, "no URL configured; skipping", :yellow
      end

      desc "migrate_database CONTEXT DATABASE_NAME", "Runs the migrations for the indicated context/database"
      method_option :version, type: :numeric
      def migrate_database(context_name, database_name, bypass_schema_dump: false)
        return unless database_managed?(context_name, database_name)

        mod = context_module(context_name)
        connection = mod.database(database_name.to_sym)

        DatabaseManager.new(connection).migrate(
          migrations_path: mod.paths.db(database_name).join('migrations'),
          target_version: options[:version],
        )

        say_with_db context_name, database_name, "migrated"

        dump_database_schema(context_name, database_name) if !bypass_schema_dump && mod.environment == "development"
      rescue Sequel::Migrator::Error => e
        say_with_db context_name, database_name, "unable to migrate: #{e.message}", :red
      rescue EventFramework::DatabaseConnection::MissingConnectionURLError
        say_with_db context_name, database_name, "no URL configured; skipping", :yellow
      end

      desc "dump_database_schema CONTEXT DATABASE_NAME", "Dumps the curent SQL schema, for the indicated context/database"
      def dump_database_schema(context_name, database_name)
        return unless database_managed?(context_name, database_name)

        mod = context_module(context_name)
        connection = mod.database(database_name.to_sym)
        schema_path = mod.paths.db(database_name).join('structure.sql')

        DatabaseManager.new(connection).dump_schema(schema_path: schema_path)
        say_with_db context_name, database_name, "schema dumped to #{schema_path}"
      end

      desc "reset_database CONTEXT DATABASE_NAME", "Drops, creates and migrates the database for the indicated context/database"
      def reset_database(_context_name, _database_name)
        invoke :drop_database
        invoke :create_database
        invoke :migrate_database
      end

      desc "prepare_all", "Creates and migrates all databases for all known contexts"
      def prepare_all
        EventFramework::Tasks.registered_contexts.each do |context_name|
          context_module(context_name).databases.each do |connection|
            create_database(context_name, connection.label.to_s)
            migrate_database(context_name, connection.label.to_s, bypass_schema_dump: true)
          end
        end
      end

      desc "reset_all", "Drops, creates and migrates the database for all databases for all known contexts"
      def reset_all
        EventFramework::Tasks.registered_contexts.each do |context_name|
          context_module(context_name).databases.each do |connection|
            drop_database(context_name, connection.label.to_s)
            create_database(context_name, connection.label.to_s)
            migrate_database(context_name, connection.label.to_s)
          end
        end
      end

      private

      # We can configure references to databases that are managed through other
      # means (e.g. our pre-migration legacy database). Before trying to
      # run any tasks involving those databases, make sure we 'own' it by
      # ensuring that a db/database_name path exists for the context.
      def database_managed?(context_name, database_name)
        database_configuration_path = context_module(context_name).paths.db(database_name)

        if Dir.exist? database_configuration_path
          true
        else
          say_with_db context_name, database_name, "'#{database_configuration_path}' doesn't exist, so we're assuming `#{database_name}` is managed elsewhere. Skipping.", :yellow
          false
        end
      end

      def say_with_db(context, db, message, color = nil)
        say "[#{context}/#{db}] #{message}", color
      end

      def context_module(name)
        inflector = Dry::Inflector.new

        EventFramework::Tasks.root_module.const_get(inflector.camelize(name), false)
      end
    end
  end
end
