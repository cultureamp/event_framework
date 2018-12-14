require 'dry/inflector'
require 'thor'

module EventFramework
  module Tasks
    class Runner < Thor
      def self.exit_on_failure?
        true
      end

      desc "create_database CONTEXT DATABASE_NAME", "Creates the PostgreSQL database for the indicated context/database"
      def create_database(context_name, database_name)
        connection = context_module(context_name).database(database_name.to_sym)

        DatabaseManager.new(connection).create
      rescue DatabaseManager::DatabaseAlreadyExistsError
        puts "#{context_name}/#{database_name} already exists, skipping"
      end

      desc "drop_database CONTEXT DATABASE_NAME", "Drops the PostgreSQL database for the indicated context/database"
      def drop_database(context_name, database_name)
        connection = context_module(context_name).database(database_name.to_sym)

        DatabaseManager.new(connection).drop
      end

      desc "migrate_database CONTEXT DATABASE_NAME", "Runs the migrations for the indicated context/database"
      method_option :version, type: :numeric
      def migrate_database(context_name, database_name, bypass_schema_dump: false)
        mod = context_module(context_name)
        connection = mod.database(database_name.to_sym)

        DatabaseManager.new(connection).migrate(
          migrations_path: mod.paths.db(database_name).join('migrations'),
          target_version: options[:version],
        )

        invoke :dump_database_schema if !bypass_schema_dump && mod.environment == "development"
      end

      desc "dump_database_schema CONTEXT DATABASE_NAME", "Dumps the curent SQL schema, for the indicated context/database"
      def dump_database_schema(context_name, database_name)
        mod = context_module(context_name)
        connection = mod.database(database_name.to_sym)

        DatabaseManager.new(connection).dump_schema(schema_path: mod.paths.db(database_name).join('structure.sql'))
      end

      desc "reset_database CONTEXT DATABASE_NAME", "Drops, creates and migrates the database for the indicated context/database"
      def reset_database(_context_name, _database_name)
        invoke :drop_database
        invoke :create_database
        invoke :migrate_database
      end

      private

      def context_module(name)
        inflector = Dry::Inflector.new

        EventFramework::Tasks.root_module.const_get(inflector.camelize(name), false)
      end
    end
  end
end
