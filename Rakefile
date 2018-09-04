require 'dotenv'
Dotenv.load '../.env'

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'event_framework'

namespace :event_store do
  namespace :db do
    desc "Run the migrate and schema-dump tasks; Set VERSION in Env to choose which migration to target"
    task migrate: ["migrate:check_configuration", "migrate:run", "schema:dump"]

    namespace :migrate do
      desc "Checks to see if EventFramework has been configured; exits cleanly if not"
      task :check_configuration do
        if EventFramework.config.database_url.nil?
          puts "No DATABASE_URL configurd for EventFramework in #{EventFramework.environment}; exiting."
          exit
        end
      end

      desc "Perform Migrations; Set VERSION in Env to choose which migration to target"
      task :run do
        require "sequel/core"

        Sequel.extension :migration

        version = ENV['VERSION']&.to_i

        puts "Migrating in #{EventFramework.environment} environment..."
        Sequel.connect(EventFramework.config.database_url) do |db|
          Sequel::Migrator.run(db, "db/migrations", target: version)
        end
      end

      desc "Create a database migration, Pass in the NAME Env var to set the filename"
      task :create do
        require 'sequel/core'
        Sequel.extension :inflector
        timestamp_prefix = Time.now.utc.strftime("%Y%m%d%H%M%S")
        migration_name = ENV["NAME"] || 'migration'

        file_name = "#{timestamp_prefix}_#{migration_name.underscore}.rb"

        File.open("db/migrations/#{file_name}", 'w') do |f|
          f << <<~MIGRATION
            Sequel.migration do
              up do
              end

              down do
              end
            end
          MIGRATION
        end
      end
    end

    desc "Reset database"
    task reset: [:drop, :create, :migrate]

    desc "Create database"
    task :create do
      require "sequel/core"

      database_uri      = URI.parse(EventFramework.config.database_url)
      root_database_uri = URI.parse(EventFramework.config.database_url).tap { |u| u.path = '/postgres' }

      db_name = File.basename(database_uri.path)

      Sequel.connect(root_database_uri.to_s) do |db|
        db.execute "CREATE DATABASE #{db_name}"
      end
    end

    desc "Drop database"
    task :drop do
      require "sequel/core"

      database_uri      = URI.parse(EventFramework.config.database_url)
      root_database_uri = URI.parse(EventFramework.config.database_url).tap { |u| u.path = '/postgres' }

      db_name = File.basename(database_uri.path)

      Sequel.connect(root_database_uri.to_s) do |db|
        db.execute "DROP DATABASE IF EXISTS #{db_name}"
      end
    end

    namespace :schema do
      desc "Dump database schema"
      task :dump do
        require_relative 'lib/tasks/schema_dump'

        SchemaDump.call(EventFramework.config.database_url, filename: 'db/structure.sql')
      end
    end
  end
end
