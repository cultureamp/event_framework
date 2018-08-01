require 'dotenv'
Dotenv.load '../.env'

namespace :event_store do
  namespace :db do
    desc "Run the migrate and schema-dump tasksl Set VERSION in Env to choose which migration to target"
    task migrate: ["migrate:run", "schema:dump"]

    namespace :migrate do
      desc "Perform Migrations; Set VERSION in Env to choose which migration to target"
      task :run do
        require "sequel/core"
        require_relative 'lib/event_framework'

        Sequel.extension :migration

        version = ENV['VERSION']&.to_i

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
      require_relative 'lib/event_framework'

      db_name = File.basename(URI.parse(EventFramework.config.database_url).path)
      Sequel.connect('postgres:///template1') do |db|
        db.execute "CREATE DATABASE #{db_name}"
      end
    end

    desc "Drop database"
    task :drop do
      require "sequel/core"
      require_relative 'lib/event_framework'

      db_name = File.basename(URI.parse(EventFramework.config.database_url).path)
      Sequel.connect('postgres:///template1') do |db|
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
